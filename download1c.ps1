# Переменные PORTAL_USER и PORTAL_PASS можно указать в этом файле,
# задать через переменные окружения или в отдельном файле credentials
#PORTAL_USER=YOUR_PORTAL_LOGIN
#PORTAL_PASS=YOUR_PORTAL_PASSWORD

param (
    [string]$DISTR_PATH = ".\distr",
    [Alias("u")][string]$PORTAL_USER,
    [Alias("p")][string]$PORTAL_PASS,
    [Alias("k")][ValidateSet("platform", "postgres")][string]$DISTR_KIND = "platform",
    [Alias("v")][string]$DISTR_VER = "8.3.19.1417",
    [Alias("t")][string]$DISTR_TYPE = "windows64full",
    [Alias("e")][string]$DISTR_EXTENSION = "rar"
)

# Читаем credentials, если есть
if (Get-ChildItem -File -Filter "credentials") {
    $matches_cred_user = Select-String "PORTAL_USER=(.+)" -Path "credentials"
    if ($matches_cred_user) {$PORTAL_USER = $matches_cred_user.Matches[0].Groups[1].Value}
    $matches_cred_pass = Select-String "PORTAL_PASS=(.+)" -Path "credentials"
    if ($matches_cred_pass) {$PORTAL_PASS = $matches_cred_pass.Matches[0].Groups[1].Value}
} else {
    # Иначе берем из переменных окружения, если соответствующие локальные переменные не заполнены
    if (!$PORTAL_USER) {$PORTAL_USER=$Env:PORTAL_USER}
    if (!$PORTAL_PASS) {$PORTAL_PASS=$Env:PORTAL_PASS}
}

# Страница с сылками на релиз
switch ($DISTR_KIND) {
    "platform" {
        $release_download_page_url = "https://releases.1c.ru/version_file?nick=Platform83&ver=${DISTR_VER}&path=Platform%5c$($DISTR_VER.Replace('.', '_'))%5c${DISTR_TYPE}_$($DISTR_VER.Replace('.', '_')).${DISTR_EXTENSION}"
        $distr_fullname = "${DISTR_PATH}\${DISTR_TYPE}_$($DISTR_VER.Replace('.', '_')).${DISTR_EXTENSION}"
    }
    "postgres" {
        $release_download_page_url = "https://releases.1c.ru/version_file?nick=AddCompPostgre&ver=${DISTR_VER}&path=AddCompPostgre%5c$($DISTR_VER.Replace('.', '_').Replace('-', '_'))%5cpostgresql_$($DISTR_VER.Replace('-', '_'))_${DISTR_TYPE}.${DISTR_EXTENSION}"
        $distr_fullname = "${DISTR_PATH}\postgresql_$($DISTR_VER.Replace('-', '_'))_${DISTR_TYPE}.${DISTR_EXTENSION}"
    }
    default { 
        Write-Error "Некорректный тип дистрибутива: $DISTR_KIND"; exit 
    }
}
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
$login_page_data = (Invoke-WebRequest -Method POST -Body $post_data -SessionVariable portal_1c_cookies "https://login.1c.ru/login").Content
if (Select-String -InputObject $login_page_data 'Неверный логин или пароль') {
    Write-Warning "не верный логин/пароль: username=${PORTAL_USER} password=${PORTAL_PASS}"
    exit
}

# На странице с ссылками на релиз, находим сгенерирвонный URL, ведущий к дистрибутиву
$release_download_page_data = (Invoke-WebRequest -Method POST -Body $post_data -WebSession $portal_1c_cookies $release_download_page_url).Content
$matches_release_url = Select-String -InputObject $release_download_page_data '(?<=a href=")[^"]+(?=">Скачать дистрибутив<)'
if ($matches_release_url) {
    $release_url =  $matches_release_url.Matches[0].Groups[0].Value
} else {
    Write-Warning "Не удалось найти ссылку на дистрибутив. Указанный релиз $DISTR_VER с расширением $DISTR_EXTENSION не существует для платформы $DISTR_TYPE!"
    exit
}

# Скачиваем дистрибутив
[void] (mkdir -Path $DISTR_PATH -Force)
Write-Host "Дистрибутив скачивается ($distr_fullname) Подождите..."
Invoke-WebRequest -WebSession $portal_1c_cookies -OutFile $distr_fullname $release_url
Write-Host "Загрузка завершена ($((Get-Item $distr_fullname).Length / 1MB) Мб)!"