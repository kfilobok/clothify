import tensorflow as tf
from tensorflow.keras.preprocessing import image
import numpy as np
import pandas as pd
import os


model_path = 'v80_4.5fashion_classifier.h5'
model = tf.keras.models.load_model(model_path)

styles_path = '/Users/kati4ka/.cache/kagglehub/datasets/paramaggarwal/fashion-product-images-dataset/versions/1/fashion-dataset/styles.csv'

styles_df = pd.read_csv(styles_path, on_bad_lines='skip')

styles_df = styles_df.dropna(subset=['articleType'])

categories_to_remove = ['Bra', 'Deodorant', 'Kurtas', 'Briefs', 'Sarees', 'Perfume and Body Mist', 'Nail Polish',
                        'Wallets', 'Earrings', 'Lipstick', 'Ties', 'Caps', 'Clutches', 'Dresses', 'Flats', 'Flip Flops', 'Socks',
                        'Backpacks', 'Belts', 'Sandals', 'Sunglasses', 'Heels', 'Handbags', 'Tops', 'Watches', 'Casual Shoes','Formal Shoes','Sports Shoes']

filtered_df = styles_df[~styles_df['articleType'].isin(categories_to_remove)]

category_counts = filtered_df['articleType'].value_counts()

sp = []
for category in category_counts.index:
    if category_counts[category] > 250:
        print(category, category_counts[category])
        sp.append(category)

# categories_to_remove = ['Bra', 'Deodorant', 'Kurtas', 'Briefs', 'Sarees', 'Perfume and Body Mist', 'Nail Polish',
#                         'Wallets', 'Earrings', 'Lipstick', 'Ties']
# print(sorted(list(set(sp) & set(categories_to_remove))))
# print(sorted(categories_to_remove))

# exit(0)



filtered_df = filtered_df[filtered_df['articleType'].map(category_counts) >= 250]


images_path = '/Users/kati4ka/.cache/kagglehub/datasets/paramaggarwal/fashion-product-images-dataset/versions/1/fashion-dataset/images'

# train_dir = './train'
# os.makedirs(train_dir, exist_ok=True)

categories = filtered_df['articleType'].unique()
print(f'Найдено {len(categories)} уникальных категорий.')
print(categories)
print(sorted(categories))



def predict_image(image_path):
    img = image.load_img(image_path, target_size=(224, 224))
    img_array = image.img_to_array(img) / 255.0
    img_array = np.expand_dims(img_array, axis=0)

    predictions = model.predict(img_array)
    # print(predictions)
    predicted_class = np.argmax(predictions)
    predicted_label = categories[predicted_class -1]
    predicted_label = predicted_class
    return predicted_label


if __name__ == "__main__":
    for root, dirs, files in os.walk("./testnetw"):
        for file in files:

            if file != ".DS_Store":
                print(file)
                file_path = os.path.join(root, file)
                if os.path.exists(file_path):
                    pred = predict_image(file_path)
                    print(f'Предсказанная категория: {pred} \t  {categories[pred]}')
                else:
                    print("Файл не найден")
            print("\n")


