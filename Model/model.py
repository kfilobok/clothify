# preprocessing_function=lambda x: tf.image.resize_with_pad(x, *image_size)

import os
import pandas as pd
import shutil
from sklearn.model_selection import train_test_split
import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras import layers, models

styles_path = '/Users/kati4ka/.cache/kagglehub/datasets/paramaggarwal/fashion-product-images-dataset/versions/1/fashion-dataset/styles.csv'

styles_df = pd.read_csv(styles_path, on_bad_lines='skip')

styles_df = styles_df.dropna(subset=['articleType'])

categories_to_remove = ['Bra', 'Deodorant', 'Kurtas', 'Briefs', 'Sarees', 'Perfume and Body Mist', 'Nail Polish',
                        'Wallets', 'Earrings', 'Lipstick', 'Ties', 'Caps', 'Clutches', 'Dresses', 'Flats', 'Flip Flops',
                        'Socks',
                        'Backpacks', 'Belts', 'Sandals', 'Sunglasses', 'Heels', 'Handbags', 'Tops', 'Watches',
                        'Casual Shoes', 'Formal Shoes', 'Sports Shoes']

filtered_df = styles_df[~styles_df['articleType'].isin(categories_to_remove)]

category_counts = filtered_df['articleType'].value_counts()

sp = []
for category in category_counts.index:
    if category_counts[category] > 250:
        print(category, category_counts[category])
        sp.append(category)

filtered_df = filtered_df[filtered_df['articleType'].map(category_counts) >= 250]

images_path = '/Users/kati4ka/.cache/kagglehub/datasets/paramaggarwal/fashion-product-images-dataset/versions/1/fashion-dataset/images'

train_dir = './train'
os.makedirs(train_dir, exist_ok=True)

categories = filtered_df['articleType'].unique()
print(f'Найдено {len(categories)} уникальных категорий')
print(categories)
# exit(0)


for category in categories:
    os.makedirs(os.path.join(train_dir, category), exist_ok=True)

for _, row in filtered_df.iterrows():
    img_name = f"{row['id']}.jpg"
    src_path = os.path.join(images_path, img_name)
    dst_path = os.path.join(train_dir, row['articleType'], img_name)
    if os.path.exists(src_path):
        shutil.copy(src_path, dst_path)

all_images = []
all_labels = []
for category in categories:
    category_path = os.path.join(train_dir, category)
    for img in os.listdir(category_path):
        all_images.append(os.path.join(category_path, img))
        all_labels.append(category)

train_images, val_images, train_labels, val_labels = train_test_split(
    all_images, all_labels, test_size=0.2, stratify=all_labels, random_state=42
)

train_df = pd.DataFrame({'filename': train_images, 'class': train_labels})
val_df = pd.DataFrame({'filename': val_images, 'class': val_labels})

input_size = (240, 160)
input_size = (224, 224)

train_datagen = ImageDataGenerator(
    rescale=1. / 255,
    rotation_range=10,
    width_shift_range=0.1,
    height_shift_range=0.1,
    shear_range=0.1,
    horizontal_flip=True,
    preprocessing_function=lambda x: tf.image.resize_with_pad(x, *input_size)
)

val_datagen = ImageDataGenerator(rescale=1. / 255)

train_generator = train_datagen.flow_from_dataframe(
    train_df,
    x_col='filename',
    y_col='class',
    target_size=input_size,
    batch_size=32,
    class_mode='categorical'
)

val_generator = val_datagen.flow_from_dataframe(
    val_df,
    x_col='filename',
    y_col='class',
    target_size=input_size,
    batch_size=32,
    class_mode='categorical'
)

my_model = MobileNetV2(input_shape=(224, 224, 3), include_top=False, weights='imagenet')
my_model.trainable = False

model = models.Sequential([
    my_model,
    layers.GlobalAveragePooling2D(),
    layers.Dense(1024, activation='relu'),
    layers.Dropout(0.5),
    layers.Dense(len(categories), activation='softmax')
])

model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])

history = model.fit(
    train_generator,
    epochs=20,
    validation_data=val_generator,
    verbose=1
)

model.save('v80_4.5fashion_classifier.h5')
