#!/bin/bash

# Функция проверки и установки зависимостей
check_dependencies() {
    echo "🔍 Проверка необходимых компонентов..."
    
    # Проверка NVM
    if [ ! -f "$HOME/.nvm/nvm.sh" ]; then
        echo "📥 Установка NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi
    
    # Загрузка NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Установка Node.js если не установлен
    if ! command -v node &> /dev/null; then
        echo "📥 Установка Node.js 18.17.0..."
        nvm install 18.17.0
        nvm use 18.17.0
    fi
    
    # Обновление npm если установлен
    if command -v npm &> /dev/null; then
        echo "📥 Обновление npm до версии 10.9.0..."
        npm install -g npm@10.9.0
    fi
    
    echo "✅ Все необходимые компоненты установлены!"
}

# Вызываем функцию проверки при запуске скрипта
check_dependencies

# Установка локали и кодировки
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8

# Принудительное использование UTF-8 для терминала
stty iutf8

# Функция для корректного отображения имени
format_name() {
    echo "$1" | iconv -f UTF-8 -t UTF-8//TRANSLIT
}

# Функция для создания нового экземпляра Nodepay
create_nodepay() {
    echo "Сколько экземпляров Nodepay вы хотите создать?"
    read instances_count
    
    for ((i=1; i<=instances_count; i++)); do
        echo "=== Настройка экземпляра $i из $instances_count ==="
        
        echo "Введите имя для нового Nodepay (например: main, test, worker):"
        read instance_name
        
        # Форматируем имя
        instance_name=$(format_name "$instance_name")
        
        # Находим следующий свободный номер
        instance_number=1
        while [ -d "nodepay$instance_number" ]; do
            instance_number=$((instance_number + 1))
        done
        
        echo "Создаю Nodepay$instance_number ($instance_name)..."
        git clone https://github.com/dante4rt/nodepay-airdrop-bot.git nodepay$instance_number
        cd nodepay$instance_number
        
        # Сохраняем имя экземпляра
        echo "$instance_name" > instance_name.txt
        
        echo "Введите токен для $instance_name:"
        read token
        echo "$token" > token.txt
        
        echo "Введите прокси для $instance_name (каждый прокси с новой строки, для завершения нажмите Ctrl+D):"
        cat > proxy.txt
        
        npm install
        
        echo "Nodepay $instance_name (ID: $instance_number) успешно создан!"
        cd ..
        echo "----------------------------------------"
    done
}

# Функция для отображения списка экземпляров
show_instances() {
    echo "📑 Доступные экземпляры Nodepay:"
    for dir in nodepay*/; do
        if [ -d "$dir" ]; then
            number=${dir//[!0-9]/}
            if [ -f "${dir}instance_name.txt" ]; then
                name=$(cat "${dir}instance_name.txt")
                echo "  🔸 Nodepay$number ($name)"
            else
                echo "  🔸 Nodepay$number (без име��и)"
            fi
        fi
    done
}

# Функция для запуска экземпляра Nodepay
start_nodepay() {
    show_instances
    
    echo "Введите номер Nodepay для запуска:"
    read instance_number
    
    if [ -d "nodepay$instance_number" ]; then
        name=$(cat "nodepay$instance_number/instance_name.txt" 2>/dev/null || echo "без имени")
        screen -S "nodepay${instance_number}_${name}" -dm bash -c "cd nodepay$instance_number && npm start"
        echo "Nodepay$instance_number ($name) запущен в screen сессии"
        echo ""
        echo "⚠️  ВАЖНО: Теперь нужно подключиться к screen сессии и ответить на вопросы программы!"
        echo "1. Нажмите Enter для подключения к screen сессии"
        echo "2. Ответьте на вопросы программы"
        echo "3. После настройки нажмите Ctrl+A, затем D для отключения от screen"
        read
        screen -r "nodepay${instance_number}_${name}"
    else
        echo "Nodepay$instance_number не существует!"
    fi
}

# Функция для просмотра логов
view_logs() {
    show_instances
    
    echo "Введите номер Nodepay для просмотра логов:"
    read instance_number
    
    if [ -d "nodepay$instance_number" ]; then
        name=$(cat "nodepay$instance_number/instance_name.txt" 2>/dev/null || echo "без имени")
        echo "Нажмите Ctrl+A, затем D для выхода из screen"
        sleep 3
        screen -r "nodepay${instance_number}_${name}"
    else
        echo "Nodepay$instance_number не существует!"
    fi
}

# Функция для остановки экземпляра Nodepay
stop_nodepay() {
    echo "Запущенные экземпляры Nodepay:"
    screen -ls | grep nodepay
    
    echo "Введите номер Nodepay для остановки:"
    read instance_number
    
    if [ -d "nodepay$instance_number" ]; then
        name=$(cat "nodepay$instance_number/instance_name.txt" 2>/dev/null || echo "без имени")
        screen -X -S "nodepay${instance_number}_${name}" quit
        echo "Nodepay$instance_number ($name) остановлен"
    else
        echo "Nodepay$instance_number не существует!"
    fi
}

# Функция для редактирования прокси
edit_proxy() {
    show_instances
    
    echo "Введите номер Nodepay для редактирования прокси:"
    read instance_number
    
    if [ -d "nodepay$instance_number" ]; then
        name=$(cat "nodepay$instance_number/instance_name.txt" 2>/dev/null || echo "без имени")
        # Останавливаем текущую screen сессию, если она существует
        screen -X -S "nodepay${instance_number}_${name}" quit 2>/dev/null
        
        echo "Редактирование proxy.txt для Nodepay$instance_number ($name)"
        echo "Введите новые прокси (каждый с новой строки, для завершения нажмите Ctrl+D):"
        cat > nodepay$instance_number/proxy.txt
        
        # Автоматически презапускаем nodepay
        screen -S "nodepay${instance_number}_${name}" -dm bash -c "cd nodepay$instance_number && npm start"
        echo "Прокси обновлены и Nodepay$instance_number ($name) перезапущен!"
    else
        echo "Nodepay$instance_number не существует!"
    fi
}

# Функция для редактирования имени
edit_name() {
    show_instances
    
    echo "Введите номер Nodepay для изменения имени:"
    read instance_number
    
    if [ -d "nodepay$instance_number" ]; then
        old_name=$(cat "nodepay$instance_number/instance_name.txt" 2>/dev/null || echo "без имени")
        echo "Текущее имя: $old_name"
        echo "Введите новое имя:"
        read new_name
        
        # Останавливаем текущую screen сессию, если она существует
        screen -X -S "nodepay${instance_number}_${old_name}" quit 2>/dev/null
        
        echo "$new_name" > "nodepay$instance_number/instance_name.txt"
        echo "Имя измнено на: $new_name"
        
        # Перезапускаем с новым именем, если была запущена сессия
        if screen -ls | grep -q "nodepay${instance_number}_${old_name}"; then
            screen -S "nodepay${instance_number}_${new_name}" -dm bash -c "cd nodepay$instance_number && npm start"
            echo "Nodepay$instance_number перезапущен с новым именем"
        fi
    else
        echo "Nodepay$instance_number не существует!"
    fi
}

# Функция для запуска всех экземпляров
start_all_nodepay() {
    echo "ВНИМАНИЕ!"
    echo "1. После запуска каждого экземпляра нужно будет подключиться к его screen сессии"
    echo "2. Ответить на вопросы программы"
    echo "3. Отключиться от screen (Ctrl+A, затем D)"
    echo "4. Перейти к настройке следующего экземпляра"
    echo ""
    echo "Выберите способ запуска:"
    echo "1. Запустить все сразу (не рекомендуется)"
    echo "2. Запустить с настройкой каждого экземпляра"
    echo "3. Отмена"
    read launch_choice

    case $launch_choice in
        1)
            echo "Запуск всех экземпляров одновременно..."
            for dir in nodepay*/; do
                if [ -d "$dir" ]; then
                    number=${dir//[!0-9]/}
                    name=$(cat "${dir}instance_name.txt" 2>/dev/null || echo "без имени")
                    screen -S "nodepay${number}_${name}" -dm bash -c "cd $dir && npm start"
                    echo "Nodepay$number ($name) запущен"
                fi
            done
            ;;
        2)
            echo "Запуск экземпляров с настройкой..."
            for dir in nodepay*/; do
                if [ -d "$dir" ]; then
                    number=${dir//[!0-9]/}
                    name=$(cat "${dir}instance_name.txt" 2>/dev/null || echo "без имени")
                    screen -S "nodepay${number}_${name}" -dm bash -c "cd $dir && npm start"
                    echo "Nodepay$number ($name) запущен"
                    echo ""
                    echo "⚠️  Настройка Nodepay$number ($name):"
                    echo "1. Нажмите Enter для подключения к screen сессии"
                    echo "2. Ответьте на вопросы программы"
                    echo "3. Нажмите Ctrl+A, затем D для перехода к следующему"
                    read
                    screen -r "nodepay${number}_${name}"
                    echo "Ожидание 5 секунд перед запуском следующего..."
                    sleep 5
                fi
            done
            ;;
        3)
            echo "Запуск отменен"
            ;;
        *)
            echo "Неверный выбор!"
            ;;
    esac
}

# Новая функция для удаления экземпляра
delete_nodepay() {
    show_instances
    
    echo "Введите номер Nodepay для удаления:"
    read instance_number
    
    if [ -d "nodepay$instance_number" ]; then
        name=$(cat "nodepay$instance_number/instance_name.txt" 2>/dev/null || echo "без имени")
        echo "⚠️  ВНИМАНИЕ! Вы собираетесь удалить Nodepay$instance_number ($name)"
        echo "Вы уверены? (y/n):"
        read confirm
        
        if [ "$confirm" = "y" ]; then
            # Останавливаем screen сессию, если она запущена
            screen -X -S "nodepay${instance_number}_${name}" quit 2>/dev/null
            # Удаляем директорию
            rm -rf "nodepay$instance_number"
            echo "🗑️  Nodepay$instance_number ($name) успешно удален!"
        else
            echo "❌ Удаление отменено"
        fi
    else
        echo "❌ Nodepay$instance_number не существует!"
    fi
}

# Обновленное главное меню
while true; do
    clear
    echo "🤖 === Управление Nodepay === 🤖"
    show_instances
    echo "------------------------"
    echo "1. 📦 Создать новый Nodepay"
    echo "2. ⚡ Запустить существующий Nodepay"
    echo "3. 🚀 Запустить ВСЕ экземпляры"
    echo "4. 📋 Просмотреть логи"
    echo "5. ⏹️  Остановить Nodepay"
    echo "6. 🔄 Редактировать прокси"
    echo "7. ✏️  Изменить имя"
    echo "8. 🗑️  Удалить экземпляр"
    echo "9. 🚪 Выход"
    echo "Выберите действие (1-9):"
    
    read choice
    
    case $choice in
        1)
            echo "📦 Создание нового экземпляра..."
            create_nodepay
            ;;
        2)
            echo "⚡ Запуск экземпляра..."
            start_nodepay
            ;;
        3)
            echo "🚀 Запуск всех экземпляров..."
            start_all_nodepay
            ;;
        4)
            echo "📋 Просмотр логов..."
            view_logs
            ;;
        5)
            echo "⏹️  Остановка экземпляра..."
            stop_nodepay
            ;;
        6)
            echo "🔄 Редактирование прокси..."
            edit_proxy
            ;;
        7)
            echo "✏️  Изменение имени..."
            edit_name
            ;;
        8)
            echo "🗑️  Удаление экземпляра..."
            delete_nodepay
            ;;
        9)
            echo "👋 До свидания!"
            exit 0
            ;;
        *)
            echo "❌ Неверный выбор!"
            ;;
    esac
    
    echo "⏎  Нажмите Enter для продолжения..."
    read
done 