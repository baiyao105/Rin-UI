"""异常类定义"""


class RinUIError(Exception):
    """基础异常"""


class ConfigError(RinUIError):
    """配置错误基类"""


class ConfigParseError(ConfigError):
    """配置解析失败"""


class ConfigWriteError(ConfigError):
    """配置写入失败"""


class WindowError(RinUIError):
    """窗口创建/加载/管理错误基类"""


class QmlLoadError(WindowError):
    """QML文件加载失败"""


class WindowNotReadyError(WindowError):
    """窗口未就绪"""


class ThemeError(RinUIError):
    """主题/背景效果错误基类"""


class TranslationError(RinUIError):
    """i18n文件加载/解析错误基类"""


class PlatformError(RinUIError):
    """当前平台不支持基类"""
