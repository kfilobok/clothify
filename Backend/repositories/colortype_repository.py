from typing import List, Dict, Optional
from sqlalchemy.orm import Session
from ..models.domain import ColorTypeQuestion, ColorTypeOption, ColorType


class ColorTypeRepository:
    def __init__(self, db: Session):
        self.db = db

    def get_questions(self) -> List[ColorTypeQuestion]:
        return self.db.query(ColorTypeQuestion).all()

    def get_question_by_id(self, question_id: int) -> Optional[ColorTypeQuestion]:
        return self.db.query(ColorTypeQuestion).filter(ColorTypeQuestion.id == question_id).first()

    def get_option_by_id(self, option_id: int) -> Optional[ColorTypeOption]:
        return self.db.query(ColorTypeOption).filter(ColorTypeOption.id == option_id).first()

    def get_color_type_by_name(self, name: str) -> Optional[ColorType]:
        return self.db.query(ColorType).filter(ColorType.name == name).first()

    def create_question(self, text: str) -> ColorTypeQuestion:
        question = ColorTypeQuestion(text=text)
        self.db.add(question)
        self.db.commit()
        self.db.refresh(question)
        return question

    def create_option(self, question_id: int, text: str, value: str) -> ColorTypeOption:
        option = ColorTypeOption(question_id=question_id, text=text, value=value)
        self.db.add(option)
        self.db.commit()
        self.db.refresh(option)
        return option

    def create_color_type(self, name: str, description: str,
                         recommended_colors: List[str],
                         avoid_colors: List[str]) -> ColorType:
        color_type = ColorType(
            name=name,
            description=description,
            recommended_colors=recommended_colors,
            avoid_colors=avoid_colors
        )
        self.db.add(color_type)
        self.db.commit()
        self.db.refresh(color_type)
        return color_type

    def seed_data(self):
        # Проверяем, есть ли уже данные
        existing_questions = self.db.query(ColorTypeQuestion).count()
        if existing_questions > 0:
            print("ColorType data already exists, skipping seed")
            return

        print("Seeding ColorType data...")
        # Создаем вопросы и варианты ответов для определения стиля
        q1 = self.create_question("Какие цвета преобладают в Вашем гардеробе?")
        self.create_option(q1.id, "Мне нравятся пастельные оттенки: бежевый, коричневый, молочный, голубой.", "casual,oldmoney")
        self.create_option(q1.id, "Базовые (белый, черный, серый) с редким добавлением акцентов.", "casual,classic")
        self.create_option(q1.id, "Я люблю яркие цвета и акцентные принты.", "sport,grunge")
        self.create_option(q1.id, "В моем гардеробе нет единого цвета.", "casual,classic,oldmoney,sport,grunge")

        q2 = self.create_question("Какие верхние элементы одежды преобладают в вашем гардеробе?")
        self.create_option(q2.id, "Рубашки, футболки поло, джемперы", "oldmoney")
        self.create_option(q2.id, "Пиджаки, жилетки, рубашки", "classic")
        self.create_option(q2.id, "Свитшоты, джинсы, свитера, футболки", "casual")
        self.create_option(q2.id, "Зипки, толстовки, худи", "sport")
        self.create_option(q2.id, "Лонгсливы, футболки", "casual,grunge")
        self.create_option(q2.id, "Нет определенных преобладающих вещей в гардеробе", "casual,classic,oldmoney,sport,grunge")

        q3 = self.create_question("Какие нижние элементы одежды преобладают в вашем гардеробе?")
        self.create_option(q3.id, "Брюки", "casual,classic,oldmoney")
        self.create_option(q3.id, "Спортивки, карго", "sport")
        self.create_option(q3.id, "Джинсы", "casual,sport,grunge")

        q4 = self.create_question("Какую обувь вы предпочитаете?")
        self.create_option(q4.id, "Кроссовки и кеды", "casual,sport")
        self.create_option(q4.id, "Мокасины и лоферы", "classic,oldmoney")
        self.create_option(q4.id, "Мартинсы и грубые ботинки", "grunge")

        q5 = self.create_question("Какой формат верхней одежды вы предпочитаете?")
        self.create_option(q5.id, "Дутая куртка", "casual,sport")
        self.create_option(q5.id, "Пальто", "classic")
        self.create_option(q5.id, "Дубленка", "grunge,oldmoney")
        self.create_option(q5.id, "Бомбер", "sport")

        q6 = self.create_question("Какие аксессуары вы носите на регулярной основе?")
        self.create_option(q6.id, "Солнечные очки", "casual")
        self.create_option(q6.id, "Часы", "oldmoney")
        self.create_option(q6.id, "Кепки и шапки", "casual,sport")
        self.create_option(q6.id, "Барсетки, спортивные сумки, рюкзаки", "sport")
        self.create_option(q6.id, "Кожаные сумки и портфели", "classic,oldmoney")
        self.create_option(q6.id, "Цепочки, кольца и т.п.", "grunge")
        self.create_option(q6.id, "Галстуки", "classic")
        self.create_option(q6.id, "Я не ношу аксессуары", "casual")

        # Создаем стили вместо цветотипов
        self.create_color_type(
            "casual",
            "Кэжуал стиль характеризуется комфортной и непринужденной одеждой. Это повседневный стиль, подходящий для большинства ситуаций.",
            ["джинсы", "футболки", "свитера", "кроссовки", "кеды", "рубашки в клетку"],
            ["формальные костюмы", "галстуки", "смокинги"]
        )

        self.create_color_type(
            "classic",
            "Классический стиль отличается элегантностью и сдержанностью. Это стиль для деловых и формальных мероприятий.",
            ["пиджаки", "брюки", "рубашки", "галстуки", "лоферы", "пальто"],
            ["спортивная одежда", "рваные джинсы", "кричащие принты"]
        )

        self.create_color_type(
            "oldmoney",
            "Стиль Old Money характеризуется высококачественными вещами с историей. Это стиль, который ассоциируется с аристократией и старыми деньгами.",
            ["поло", "джемперы", "качественные часы", "лоферы", "пастельные цвета", "твидовые пиджаки"],
            ["логотипы брендов", "неоновые цвета", "спортивная одежда"]
        )

        self.create_color_type(
            "sport",
            "Спортивный стиль это удобство и функциональность. Идеален для активного образа жизни.",
            ["кроссовки", "толстовки", "спортивные штаны", "футболки", "бомберы", "кепки"],
            ["формальная одежда", "классические туфли", "галстуки"]
        )

        self.create_color_type(
            "grunge",
            "Гранж стиль отражает бунтарский дух и нонконформизм. Характеризуется потертыми, рваными вещами и темными цветами.",
            ["рваные джинсы", "футболки с принтами", "фланелевые рубашки", "мартинсы", "кожаные куртки", "украшения"],
            ["деловые костюмы", "яркие цвета", "формальная одежда"]
        )