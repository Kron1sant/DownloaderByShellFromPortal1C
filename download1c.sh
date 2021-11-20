#!/bin/bash

# Переменные PORTAL_USER и PORTAL_PASS можно указать в этом файле, расскоментировав строки ниже
# задать через переменные окружения или в отдельном файле credentials
#PORTAL_USER=YOUR_PORTAL_LOGIN
#PORTAL_PASS=YOUR_PORTAL_PASSWORD
[ -r credentials ] && source credentials

# Параметры, определяющие скачиваемый реализ
[ -z $PLATFORM_VER ] && PLATFORM_VER=8.3.20.1613
[ -z $PLATFORM_TYPE ] && PLATFORM_TYPE=server64
[ -z $DISTR_EXTENSION ] && DISTR_EXTENSION=tar.gz
# По умолчанию дистрибутивы скачиваются в подкаталог distr текущего каталога. 
# Но можно указать путь к каталогу дистрибутивом в первом параметре
DISTR_PATH=./distr
[ $# = 1 ] && DISTR_PATH=$1

# Страница с сылками на релиз
release_download_page_url="https://releases.1c.ru/version_file?nick=Platform83&ver=${PLATFORM_VER}&path=Platform%5c${PLATFORM_VER//\./_}%5c${PLATFORM_TYPE}_${PLATFORM_VER//\./_}.${DISTR_EXTENSION}"

# Получение cookies для портала 1С. Cookies сохраняем во временный файл .portal_1c_cookies.tmp
execution_code=`wget -qO- https://releases.1c.ru | grep -oP '(?<=input type="hidden" name="execution" value=")[^"]+(?=")'`
post_data="username=${PORTAL_USER}&password=${PORTAL_PASS}&execution=${execution_code}&_eventId=submit"
wget -qO- --keep-session-cookies --save-cookies .portal_1c_cookies.tmp --post-data $post_data https://login.1c.ru/login > /dev/null

# На странице с ссылками на релиз, находим сгенерирвонный URL, ведущий к дистрибутиву
release_download_page_data=`wget -qO- --load-cookies .portal_1c_cookies.tmp $release_download_page_url`
release_url=`echo $release_download_page_data | grep -oP '(?<=a href=")[^"]+(?=">Скачать дистрибутив<)'`
if [ "x$release_url" != "x" ]
then
    # Скачиваем дистрибутив
    mkdir -p "$DISTR_PATH"
    wget -O "$DISTR_PATH"/$PLATFORM_TYPE_$PLATFORM_VER.$DISTR_EXTENSION --load-cookies .portal_1c_cookies.tmp $release_url
else
    echo "Не удалось получить url-для скачивания"
    [[ `echo $release_download_page_data` =~ "Указанный файл не найден" ]] && echo "Указанный релиз $PLATFORM_VER с расширением $DISTR_EXTENSION не существует для платформы $PLATFORM_TYPE!"
fi
# Удаляем файл с cookies
rm .portal_1c_cookies.tmp