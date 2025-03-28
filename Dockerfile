#!/bin/bash

# Проверяем, запущен ли скрипт с правами root
if [ "$(id -u)" -ne 0 ]; then
  echo "Этот скрипт должен быть запущен с правами root" >&2
  exit 1
fi

# Запрашиваем порт у пользователя
read -p "Введите порт для SSH сервера (по умолчанию 2222): " SSH_PORT
SSH_PORT=${SSH_PORT:-2222}

# Проверяем, что введен корректный порт
if ! [[ "$SSH_PORT" =~ ^[0-9]+$ ]] || [ "$SSH_PORT" -lt 1 ] || [ "$SSH_PORT" -gt 65535 ]; then
  echo "Ошибка: $SSH_PORT не является допустимым номером порта (1-65535)"
  exit 1
fi

echo "Установка SSH сервера на порту $SSH_PORT..."

# Обновляем пакеты и устанавливаем SSH сервер
apt-get update
apt-get install -y openssh-server

# Настраиваем SSH: меняем порт и разрешаем вход root по паролю (для примера)
sed -i "s/#Port 22/Port $SSH_PORT/" /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Перезапускаем SSH сервер
if systemctl status ssh >/dev/null 2>&1; then
  systemctl restart ssh
else
  service ssh restart
fi

# Устанавливаем пароль для root (например, "password") - измените на свой!
echo "root:password" | chpasswd

# Дополнительная настройка для работы systemd в контейнере
if grep -q "container" /proc/1/environ 2>/dev/null; then
  echo "Настройка для работы systemd в контейнере..."
  apt-get install -y dbus
  # Альтернатива: использовать образ с поддержкой systemd
fi

echo "--------------------------------------------------"
echo " SSH сервер успешно настроен!"
echo " Для подключения используйте:"
echo " ssh -p $SSH_PORT root@<IP_адрес>"
echo " Пароль: password"
echo "--------------------------------------------------"
echo " ВАЖНО: Не забудьте изменить пароль root!"
echo "        Для этого выполните в контейнере: passwd"
echo "--------------------------------------------------"
