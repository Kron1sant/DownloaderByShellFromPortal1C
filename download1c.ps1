# Переменные PORTAL_USER и PORTAL_PASS можно указать в этом файле, расскоментировав строки ниже
# задать через переменные окружения или в отдельном файле credentials
#PORTAL_USER=YOUR_PORTAL_LOGIN
#PORTAL_PASS=YOUR_PORTAL_PASSWORD

# Читаем credentials, если есть
if ([System.IO.File]::Exists("credentials")) {
    $matches_cred_user = Select-String "PORTAL_USER=(.+)" -Path "credentials"
    if ($matches_cred_user) {$PORTAL_USER = $matches_cred_user.Matches[0].Groups[1].Value}
    $matches_cred_pass = Select-String "PORTAL_PASS=(.+)" -Path "credentials"
    if ($matches_cred_pass) {$PORTAL_PASS = $matches_cred_pass.Matches[0].Groups[1].Value}
} else {
    # Иначе берем из переменных окружения, если соответствующие такие локальные переменные не заполнены
    if (!$PORTAL_USER) {$PORTAL_USER=$Env:PORTAL_USER}
    if (!$PORTAL_PASS) {$PORTAL_PASS=$Env:PORTAL_PASS}
}

$DEFAULT_PLATFORM_VER    = "8.3.20.1613"
$DEFAULT_PLATFORM_TYPE   = "windows64full"
$DEFAULT_DISTR_EXTENSION = "rar"

# Параметры, определяющие скачиваемый реализ
if (!$PLATFORM_VER) {if ($Env:PLATFORM_VER) {$PLATFORM_VER=$Env:PLATFORM_VER} else {$PLATFORM_VER=$DEFAULT_PLATFORM_VER}}
if (!$PLATFORM_TYPE) {if ($Env:PLATFORM_TYPE) {$PLATFORM_TYPE=$Env:PLATFORM_TYPE} else {$PLATFORM_TYPE=$DEFAULT_PLATFORM_TYPE}}
if (!$DISTR_EXTENSION) {if ($Env:DISTR_EXTENSION) {$DISTR_EXTENSION=$Env:DISTR_EXTENSION} else {$DISTR_EXTENSION=$DEFAULT_DISTR_EXTENSION}}
# По умолчанию дистрибутивы скачиваются в подкаталог distr текущего каталога. 
# Но можно указать путь к каталогу c дистрибутивом в первом параметре
$DISTR_PATH=".\distr"
if ($args[0]) {$DISTR_PATH=$args[0]}

# Страница с сылками на релиз
$release_download_page_url = "https://releases.1c.ru/version_file?nick=Platform83&ver=${PLATFORM_VER}&path=Platform%5c$($PLATFORM_VER.Replace('.', '_'))%5c${PLATFORM_TYPE}_$($PLATFORM_VER.Replace('.', '_')).${DISTR_EXTENSION}"
Write-Host "Страница дистрибутива: $release_download_page_url"

# Отключим вывод прогресса скачивания - с ним скорость падает на порядок
$ProgressPreference = 'SilentlyContinue' 

# Получение cookies для портала 1С. Cookies сохраняем во временный файл .portal_1c_cookies.tmp
$matches_execution_code = (Invoke-WebRequest "https://releases.1c.ru").Content | Select-String '(?<=input type="hidden" name="execution" value=")[^"]+(?=")'
if ($matches_execution_code) {
    $execution_code = $matches_execution_code.Matches[0].Groups[0].Value
} else {
    Write-Warning "Не удалось получить Execution код. Ошибка в парсинге страницы https://releases.1c.ru"
    exit
}
$post_data = "username=${PORTAL_USER}&password=${PORTAL_PASS}&execution=${execution_code}&_eventId=submit"
[void] (Invoke-WebRequest -Method POST -Body $post_data -SessionVariable portal_1c_cookies "https://login.1c.ru/login")

# На странице с ссылками на релиз, находим сгенерирвонный URL, ведущий к дистрибутиву
$release_download_page_data = (Invoke-WebRequest -Method POST -Body $post_data -WebSession $portal_1c_cookies $release_download_page_url).Content
$matches_release_url = Select-String -InputObject $release_download_page_data '(?<=a href=")[^"]+(?=">Скачать дистрибутив<)'
if ($matches_release_url) {
    $release_url =  $matches_release_url.Matches[0].Groups[0].Value
} else {
    Write-Warning "Не удалось найти ссылку на дистрибутив. Указанный релиз $PLATFORM_VER с расширением $DISTR_EXTENSION не существует для платформы $PLATFORM_TYPE!"
    exit
}

# Скачиваем дистрибутив
[void] (mkdir -Path $DISTR_PATH -Force)
$distr_fullname = "$DISTR_PATH\$PLATFORM_TYPE_$PLATFORM_VER.$DISTR_EXTENSION"
Write-Host "Дистрибутив скачивается ($distr_fullname) Подождите..."
Invoke-WebRequest -WebSession $portal_1c_cookies -OutFile $distr_fullname $release_url
Write-Host "Загрузка завершена ($((Get-Item $distr_fullname).Length / 1MB) Мб)!"