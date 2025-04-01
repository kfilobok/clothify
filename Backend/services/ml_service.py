import base64
import os
import random
import io
from typing import List, Dict, Any
from fastapi import HTTPException, status
import uuid
from PIL import Image
import tensorflow as tf
import numpy as np
import reqcol

from Backend.models.schemas import MLImageUpload, DetectedClothing, RecognizeResponse, SegmentationResponse

try:
    from g4f.client import Client
    g4f_client_available = True
except ImportError:
    g4f_client_available = False
    class DummyClient:
        def __init__(self, *args, **kwargs):
            self.chat = DummyChat()

        class DummyChat:
            def completions(self):
                return DummyCompletions()

            create = completions

        class DummyCompletions:
            def create(self, *args, **kwargs):
                return DummyResponse()

        class DummyResponse:
            def __init__(self):
                self.choices = [DummyChoice()]

        class DummyChoice:
            def __init__(self):
                self.message = DummyMessage()

        class DummyMessage:
            def __init__(self):
                self.content = '[]'

class MLService:
    def __init__(self):
        self.upload_dir = os.path.join(os.getcwd(), "uploads")
        os.makedirs(self.upload_dir, exist_ok=True)

        try:
            self.model = tf.keras.models.load_model("v80_4.5fashion_classifier.h5")
            print("Fashion classifier model loaded successfully")
        except Exception as e:
            print(f"Failed to load fashion classifier model: {e}")
            self.model = None

    def recognize_clothing(self, image_data: MLImageUpload) -> RecognizeResponse:
        image_path = self._save_image(image_data)

        if not os.path.exists(image_path):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to save image"
            )

        detected_items = []

        try:
            color_name, _ = reqcol.detect_clothing_color(image_path)

            if self.model:
                item_type = self._predict_clothing_type(image_path)
                confidence = 0.85
            else:
                item_type = self._predict_from_filename(image_data.file_name)
                confidence = 0.7

            width, height = Image.open(image_path).size

            detected_items.append(
                DetectedClothing(
                    type=item_type,
                    color=color_name,
                    confidence=confidence,
                    x=width // 4,
                    y=height // 4,
                    width=width // 2,
                    height=height // 2
                )
            )
        except Exception as e:
            print(f"Error during recognition: {e}")
            detected_items.append(
                DetectedClothing(
                    type="неизвестно",
                    color="неизвестно",
                    confidence=0.5,
                    x=0,
                    y=0,
                    width=100,
                    height=100
                )
            )

        return RecognizeResponse(detected_items=detected_items)

    def segment_image(self, image_data: MLImageUpload) -> SegmentationResponse:
        image_path = self._save_image(image_data)

        try:
            original_image = Image.open(image_path)

            if original_image.mode != 'RGBA':
                original_image = original_image.convert('RGBA')

            background_color = original_image.getpixel((0, 0))
            transparent_image = Image.new("RGBA", original_image.size, (0, 0, 0, 0))

            for y in range(original_image.size[1]):
                for x in range(original_image.size[0]):
                    current_color = original_image.getpixel((x, y))
                    diff = sum(abs(a-b) for a, b in zip(current_color, background_color))
                    if diff > 50:
                        transparent_image.putpixel((x, y), current_color)

            filename = f"segmented_{os.path.basename(image_path)}"
            segmented_path = os.path.join(self.upload_dir, filename)
            transparent_image.save(segmented_path, "PNG")

            return SegmentationResponse(segmented_image_url=f"/uploads/{filename}")
        except Exception as e:
            print(f"Error during segmentation: {e}")
            return SegmentationResponse(segmented_image_url=f"/uploads/{os.path.basename(image_path)}")

    def _save_image(self, image_data: MLImageUpload) -> str:
        try:
            image_binary = base64.b64decode(image_data.file_data)
            filename = f"{uuid.uuid4()}_{image_data.file_name}"
            filepath = os.path.join(self.upload_dir, filename)

            with open(filepath, "wb") as f:
                f.write(image_binary)

            return filepath
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Failed to save image: {str(e)}"
            )

    def _predict_clothing_type(self, image_path: str) -> str:
        img = Image.open(image_path).convert('RGB')
        img = img.resize((224, 224))
        img_array = np.array(img) / 255.0
        img_array = np.expand_dims(img_array, axis=0)

        prediction = self.model.predict(img_array)
        class_index = np.argmax(prediction[0])

        clothing_types = [
            "футболка", "брюки", "платье", "куртка", "рубашка",
            "свитер", "джинсы", "обувь", "шорты", "юбка"
        ]

        if class_index < len(clothing_types):
            return clothing_types[class_index]
        else:
            return "неизвестно"

    def _predict_from_filename(self, filename: str) -> str:
        filename = filename.lower()
        type_keywords = {
            "shirt": "рубашка",
            "tshirt": "футболка",
            "dress": "платье",
            "pants": "брюки",
            "jeans": "джинсы",
            "jacket": "куртка",
            "shoes": "обувь"
        }

        for keyword, value in type_keywords.items():
            if keyword in filename:
                return value

        return "неизвестно"

    def _mock_clothing_detection(self) -> RecognizeResponse:
        clothing_types = ["футболка", "брюки", "куртка", "платье", "рубашка", "джинсы", "свитер"]
        colors = ["черный", "белый", "синий", "красный", "зеленый", "желтый", "серый"]

        num_items = random.randint(1, 3)
        detected_items = []

        for _ in range(num_items):
            detected_items.append(
                DetectedClothing(
                    type=random.choice(clothing_types),
                    color=random.choice(colors),
                    confidence=round(random.uniform(0.7, 0.98), 2),
                    x=random.randint(0, 300),
                    y=random.randint(0, 300),
                    width=random.randint(100, 300),
                    height=random.randint(100, 400)
                )
            )

        return RecognizeResponse(detected_items=detected_items)