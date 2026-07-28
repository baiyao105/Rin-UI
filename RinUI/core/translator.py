from pathlib import Path

from PySide6.QtCore import QLocale, QTranslator

from .config import RINUI_PATH
from .errors import TranslationError


class RinUITranslator(QTranslator):
    """
    RinUI i18n translator.
    :param locale: QLocale, optional, default is system locale
    """

    _LANGUAGES_DIR = Path(RINUI_PATH) / "RinUI" / "languages"

    def __init__(self, locale: QLocale | None = None, parent=None):  # follow system
        super().__init__(parent)
        self.load(locale or QLocale.system())

    def load(self, locale: QLocale) -> bool:
        """
        Load translation file for the given locale.
        :param locale: QLocale, the locale to load (eg = QLocale(QLocale.Chinese, QLocale.China), QLocale("zh_CN"))
        :return: bool
        :raises TranslationError: Language directory not found or translation file cannot be loaded
        """
        locale_name = locale.name()
        path = self._LANGUAGES_DIR / f"{locale_name}.qm"

        if not path.exists():
            raise TranslationError(
                f"Language file {locale_name} not found in {self._LANGUAGES_DIR}"
            )

        QLocale().setDefault(locale)
        try:
            result = super().load(str(path))
        except Exception as e:
            raise TranslationError(f"Error loading translation: {e}") from e
        if not result:
            raise TranslationError(f"Failed to load translation file: {path}")
        return result
