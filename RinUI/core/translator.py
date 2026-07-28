from pathlib import Path

from PySide6.QtCore import QLocale, QTranslator

from .config import RINUI_PATH


class RinUITranslator(QTranslator):
    """
    RinUI i18n translator.
    :param locale: QLocale, optional, default is system locale
    """

    _LANGUAGES_DIR = Path(RINUI_PATH) / "RinUI" / "languages"

    def __init__(
        self, locale: QLocale = QLocale.system().name(), parent=None
    ):  # follow system
        super().__init__(parent)
        self.load(locale or QLocale())

    def load(self, locale: QLocale) -> bool:
        """
        Load translation file for the given locale.
        :param locale: QLocale, the locale to load (eg = QLocale(QLocale.Chinese, QLocale.China), QLocale("zh_CN"))
        :return: bool
        """
        locale_name = locale.name()
        print(f"🌏 Current locale: {locale_name}")
        path = self._LANGUAGES_DIR / f"{locale_name}.qm"

        if not path.exists():
            print(
                f'Language file "{locale_name}" not found. Fallback to default (en_US)'
            )
            path = self._LANGUAGES_DIR / "en_US.qm"
            locale = QLocale("en_US")

        QLocale().setDefault(locale)
        try:
            result = super().load(str(path))
        except Exception as e:
            print(f"Error loading translation: {e}")
            return False
        if not result:
            print(f"Warning: Failed to load translation file: {path}")
        return result
