#!/bin/bash

# Переменные PORTAL_USER и PORTAL_PASS можно указать в этом файле, расскоментировав строки ниже
# задать через переменные окружения или в отдельном файле credentials
#PORTAL_USER=YOUR_PORTAL_LOGIN
#PORTAL_PASS=YOUR_PORTAL_PASSWORD
[ -r credentials ] && source credentials

# Если первым параметром указан не ключ, считаем, что это путь к каталогу
if [ ! ${1:0:1} = '-' ] 
then 
    DISTR_PATH=$1
    shift
else
    # По умолчанию дистрибутивы скачиваются в подкаталог distr текущего каталога. 
    # Но можно указать путь к каталогу дистрибутивом в первом параметре
    DISTR_PATH=./distr
fi

while getopts 'u:p:k:v:t:e:' opt
do
    case $opt in 
        u) PORTAL_USER=$OPTARG;;
        p) PORTAL_PASS=$OPTARG;;
        k) DISTR_KIND=$OPTARG;;
        v) DISTR_VER=$OPTARG;;
        t) DISTR_TYPE=$OPTARG;;
        e) DISTR_EXTENSION=$OPTARG;;
    esac
done


# Параметры, определяющие скачиваемый реализ
[ -z $DISTR_KIND ] && DISTR_KIND=platform # "platform", "postgres"
[ -z $DISTR_VER ] && DISTR_VER=8.3.19.1417
[ -z $DISTR_TYPE ] && DISTR_TYPE=deb64
[ -z $DISTR_EXTENSION ] && DISTR_EXTENSION=tar.gz

# Страница с сылками на релиз
case $DISTR_KIND in 
    platform) 
        release_download_page_url="https://releases.1c.ru/version_file?nick=Platform83&ver=${DISTR_VER}&path=Platform%5c${DISTR_VER//\./_}%5c${DISTR_TYPE}_${DISTR_VER//\./_}.${DISTR_EXTENSION}";;
    postgres) 
        release_download_page_url="https://releases.1c.ru/version_file?nick=AddCompPostgre&ver=${DISTR_VER}&path=AddCompPostgre%5c${DISTR_VER//[\.-]/_}%5cpostgresql_${DISTR_VER//-/_}_${DISTR_TYPE}.${DISTR_EXTENSION}";;
    *) 
        echo "Некорректный тип дистрибутива: $DISTR_KIND"
        exit 1;;
esac
echo "Страница дистрибутива: $release_download_page_url"

# Получение cookies для портала 1С. Cookies сохраняем во временный файл .portal_1c_cookies.tmp
execution_code=`wget -qO- https://releases.1c.ru | grep -oP '(?<=input type="hidden" name="execution" value=")[^"]+(?=")'`
post_data="username=${PORTAL_USER}&password=${PORTAL_PASS}&execution=${execution_code}&_eventId=submit"
wget -qO- --keep-session-cookies --save-cookies .portal_1c_cookies.tmp --post-data $post_data https://login.1c.ru/login > /dev/null

# На странице с ссылками на релиз, находим сгенерированный URL, ведущий к дистрибутиву
release_download_page_data=`wget -qO- --load-cookies .portal_1c_cookies.tmp $release_download_page_url`
release_url=`echo $release_download_page_data | grep -oP '(?<=a href=")[^"]+(?=">Скачать дистрибутив<)'`
if [ "x$release_url" != "x" ]
then
    # Скачиваем дистрибутив
    mkdir -p "$DISTR_PATH"
    distr_fullname="$DISTR_PATH/$DISTR_TYPE_$DISTR_VER.$DISTR_EXTENSION"
    echo "Дистрибутив скачивается ($distr_fullname) Подождите..."
    wget -O $distr_fullname --load-cookies .portal_1c_cookies.tmp $release_url
else
    echo "Не удалось получить url-для скачивания"
    [[ `echo $release_download_page_data` =~ "Указанный файл не найден" ]] && echo "Указанный релиз $DISTR_VER с расширением $DISTR_EXTENSION не существует для платформы $DISTR_TYPE!"
fi
echo "Загрузка завершена ($(ls -lh "$distr_fullname" 2> /dev/null | cut -d' ' -f5 2> /dev/null))!"
# Удаляем файл с cookies
rm .portal_1c_cookies.tmp