import os
from PIL import Image
import numpy as np



def get_random_pixels(image, num_pixels=80):
    # pixels = list(image.getdata())
    # sp= random.sample(pixels, min(num_pixels, len(pixels)))
    sp=[]
    st={(46, 24), (49, 23), (31, 23), (31, 26), (45, 22), (47, 25), (36, 22), (47, 28), (42, 23), (42, 26), (33, 23), (44, 23), (44, 26), (35, 26), (49, 25), (35, 29), (38, 22), (48, 29), (31, 25), (31, 22), (45, 21), (34, 21), (37, 26), (36, 24), (47, 24), (42, 22), (42, 28), (44, 28), (35, 28), (39, 22), (38, 24), (31, 24), (45, 26), (36, 23), (47, 23), (37, 22), (42, 24), (44, 21), (41, 28), (44, 24)}
    # st=set()
    # while len(st)<num_pixels//2:
    #     st.add((random.randint(31,39), random.randint(21,29)))
    #     st.add((random.randint(41, 49), random.randint(21, 29)))
    # print(len(st))
    # print(st)

    for x, y in st:
        sp.append(image.getpixel((x, y)))

    print(sp)

    return sp


def average_color(pixels):
    pixels_rgb = [pixel[:3] for pixel in pixels]
    return tuple(np.mean(pixels_rgb, axis=0).astype(int))


def classify_color(rgb):
    r, g, b = rgb
    brightness = (r + g + b) / 3

    if brightness < 50:
        return "Черный"
    elif brightness > 240:
        return "Белый"
    elif 50 <= brightness <= 200:
        if abs(r - g) < 30 and abs(g - b) < 30 and abs(r - b) < 30:
            return "Серый"

    if r > g and r > b:
        if g < 100 and b < 100:
            if r > 200:
                return "Красный"
            else:
                return "Бордовый"
        elif g > 100 and b < 100:
            if r > 200:
                return "Оранжевый"
            else:
                return "Коричневый"
        elif g > 100 and b > 100:
            return "Розовый"

    if g > r and g > b:
        if r < 100 and b < 100:
            return "Зеленый"
        elif r > 100 and b < 100:
            return "Оливковый"

    if b > r and b > g:
        if r < 100 and g < 100:
            return "Синий"
        elif r < 100 and g > 100:
            return "Голубой"
        elif r > 100 and g < 100:
            return "Фиолетовый"

    if r > 150 and g > 150 and b < 100:
        if r > 200 and g > 200:
            return "Желтый"
        else:
            return "Бежевый"

    return "Неопределенный"


def detect_clothing_color(image_path, num_pixels=80):
    image = Image.open(image_path).convert('RGB')

    # Сжатие изображения
    compressed_image = image.resize((80, 80))
    # compressed_image.save('compressed_image.jpg')
    # left = 31  # Начало по горизонтали (X)
    # top = 21  # Начало по вертикали (Y)
    # right = 50  # Конец по горизонтали (X)
    # bottom = 31  # Конец по вертикали (Y)
    #
    # cropped_image = compressed_image.crop((left, top, right, bottom))
    # cropped_image.save('cropped_fragment.jpg')

    pixels = get_random_pixels(compressed_image, num_pixels)
    avg_color = average_color(pixels)
    color_name = classify_color(avg_color)

    return color_name, avg_color






def test():
    for root, dirs, files in os.walk("./testnetw"):
        for file in files:

            if file != ".DS_Store":
                print(file)
                file_path = os.path.join(root, file)
                if os.path.exists(file_path):
                    color_name, avg_color = detect_clothing_color(file_path)
                    print(f"Цвет одежды: {color_name}, Средний цвет: {avg_color}")

                    image = Image.open(file_path).convert('RGB')
                    compressed_image = image.resize((80, 80))
                    compressed_image.save(f'{file}compressed_image.jpg')
                    left = 31
                    top = 21
                    right = 50
                    bottom = 31

                    cropped_image = compressed_image.crop((left, top, right, bottom))
                    cropped_image.save(f'{file}cropped_fragment.jpg')
                else:
                    print("Файл не найден")
            print("\n")















