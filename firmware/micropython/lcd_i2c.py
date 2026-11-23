# Pilote minimal pour écran LCD HD44780 (16×2, 20×4) avec module I2C PCF8574.
# Câblage du PCF8574 (standard) : P0=RS, P1=RW, P2=E, P3=rétroéclairage, P4..P7=D4..D7.

import time

_RS = 0x01
_EN = 0x04
_BACKLIGHT = 0x08


class LcdI2C:
    def __init__(self, i2c, addr=0x27, cols=16, rows=2):
        self.i2c = i2c
        self.addr = addr
        self.cols = cols
        self.rows = rows
        self._bl = _BACKLIGHT
        time.sleep_ms(50)
        # Séquence d'initialisation en mode 4 bits.
        for _ in range(3):
            self._write4(0x30)
            time.sleep_ms(5)
        self._write4(0x20)
        time.sleep_ms(1)
        self.command(0x28)  # 4 bits, 2 lignes, police 5×8
        self.command(0x08)  # affichage éteint
        self.clear()
        self.command(0x06)  # curseur vers la droite
        self.command(0x0C)  # affichage allumé, curseur masqué

    # --- bas niveau -------------------------------------------------------
    def _out(self, value):
        self.i2c.writeto(self.addr, bytes([value | self._bl]))

    def _write4(self, data, rs=0):
        b = (data & 0xF0) | rs
        self._out(b | _EN)
        time.sleep_us(1)
        self._out(b)
        time.sleep_us(50)

    def _send(self, value, rs):
        self._write4(value & 0xF0, rs)
        self._write4((value << 4) & 0xF0, rs)

    # --- API ----------------------------------------------------------------
    def command(self, cmd):
        self._send(cmd, 0)
        if cmd in (0x01, 0x02):
            time.sleep_ms(2)

    def clear(self):
        self.command(0x01)

    def move_to(self, col, row):
        offsets = (0x00, 0x40, 0x14, 0x54)
        self.command(0x80 | (col + offsets[row % 4]))

    def putstr(self, text):
        for ch in text:
            code = ord(ch)
            if code == 0xB0:  # « ° » → caractère degré du LCD
                code = 0xDF
            elif code > 0xFF:
                code = ord("?")
            self._send(code, _RS)

    def write_line(self, row, text):
        """Écrit une ligne complète (complétée par des espaces)."""
        self.move_to(0, row)
        self.putstr((text + " " * self.cols)[: self.cols])

    def backlight(self, on=True):
        self._bl = _BACKLIGHT if on else 0
        self._out(0)
