import unittest
import tensorflow as tf
import numpy as np
from tensorflow.keras.preprocessing.image import ImageDataGenerator

<<<<<<< HEAD
=======

>>>>>>> df7d4318d55a2569deaee35970a45e83bc5d1223
class TestFashionClassifier(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.model = tf.keras.models.load_model('/Users/kati4ka/Documents/projects/pythonProject/classificationAi/v20_4.5fashion_classifier.h5')
        cls.input_size = (224, 224)
        cls.num_classes = len(cls.model.output_shape[-1])

    def prejob(self, image_path):
        image = tf.keras.preprocessing.image.load_img(image_path, target_size=self.input_size)
        image = tf.keras.preprocessing.image.img_to_array(image)
        image = np.expand_dims(image, axis=0)
        image = image / 255.0
        return image

    def test_model_accuracy(self):
        val_datagen = ImageDataGenerator(rescale=1. / 255)
        val_generator = val_datagen.flow_from_directory(
            './train',
            target_size=self.input_size,
            batch_size=32,
            class_mode='categorical',
            shuffle=False
        )
        loss, accuracy = self.model.evaluate(val_generator, verbose=0)
        print(f'Validation Accuracy: {accuracy * 100:.2f}%')
        self.assertGreater(accuracy, 0.7, "Cлишком низкая точность!")

    def test_single_image_prediction(self):
        test_image = './tshirt.JPEG'
        image = self.prejob(test_image)
        prediction = self.model.predict(image)
        predicted_class = np.argmax(prediction)
        self.assertTrue(0 <= predicted_class < self.num_classes, "Некорректный класс предсказания")

    def test_model_robustness(self):
        test_image = './tshirt.JPEG'
        image = self.prejob(test_image)
        noise = np.random.normal(0, 0.05, image.shape)
        noisy_image = np.clip(image + noise, 0, 1)  # Добавляем шум и обрезаем значения
        prediction = self.model.predict(noisy_image)
        predicted_class = np.argmax(prediction)
        self.assertTrue(0 <= predicted_class < self.num_classes, "Модель не устойчива к шуму")

if __name__ == '__main__':
    unittest.main()
