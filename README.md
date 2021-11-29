# СКРИПТ ДЛЯ СКАЧИВАНИЯ ДИСТРИБУТИВОВ С ПОРТАЛА releases.1c.ru

### Скачать 1С 8.3.19.1417 в каталог distr\1c_win64 под Windows 64 бита
Для **PowerShell**:
```powershell
.\download1c.ps1 distr\1c_win64 -v 8.3.19.1417 -t windows64full -e rar
```


### Скачать PostgreSQL 12.7-5.1C в каталог distr\postrges_win64 под Windows 64 бита
Для **PowerShell**:
```powershell
.\download1c.ps1 distr\postrges_win64 -k postgres -v 12.7-5.1C -t x64 -e zip
```

### Скачать 1С 8.3.19.1417 в каталог distr\1c_deb64 под Linux(deb) 64 бита
Для **bash**:
```bash
./download1c.sh distr/1c_deb64 -v 8.3.19.1417 -t deb64 -e tar.gz
```

### Скачать PostgreSQL 12.7-5.1C в каталог distr\postrges_deb64 под Linux(deb) 64 бита
Для **bash**:
```bash
./download1c.sh distr/postrges_deb64 -k postgres -v 12.7-5.1C -t amd64_deb -e tar.bz2
```

Для запуска необходимо задать параметры:
 * <первый параметр без ключа> | DISTR_PATH - путь к каталогу, куда скачивается дистрибутив. По умолчанию: '.\distr' (подкаталог относительно текущего каталога);
 * -u | PORTAL_USER - пользователь портала 1С;
 * -p | PORTAL_PASS - пароль пользователя портала 1С;
 * -k | DISTR_KIND - вид дистриьутива: "platform", "postgres";
 * -v | DISTR_VER - версия дистрибутива (например, **8.3.19.1417** для 1С или **12.7-5.1C** для Postgres);
 * -t | DISTR_TYPE - тип платформы (например, **windows64full** или **deb64**);
 * -e | DISTR_EXTENSION - расширение файла дистрибутива (например, **rar**).

Переменные **PORTAL_USER** и **PORTAL_PASS** можно указать в файле скрипта, или задать через переменные окружения, или в отдельном файле **credentials**