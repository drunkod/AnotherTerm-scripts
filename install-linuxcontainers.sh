#!/system/bin/sh

# Различные архивы linux rootfs из сценария установки linuxcontainers.org.

set -e

###
show_usage() {
echo 'Usage:'
echo "  $0 [-a] [-d] [-e] [--] <distro> <release> [<target_subdir_name>]"
echo '    -a -- non-interactive mode'
echo '    -d -- do not use minitar and PRoot from a plugin if present'
echo '    -e -- fail if no minitar or PRoot from a plugin are present'
echo
echo 'Variables:'
echo '  REG_USER - user account name; default:' "$REG_USER"
echo '  FAV_SHELL - preferable shell; default:' "$FAV_SHELL" '(fallback: /bin/sh)'
echo '  PROOT - proot location; default: <auto>'
echo '  PROOT_USERLAND - proot userland flavor location; default: <auto>'
echo '  ESSENTIALS_PKG - Application ID of a minitar and PRoot plugin to check; default:' "$ESSENTIALS"
echo '  ROOTFS_URL - override root FS source URL'
}
###

# Мы не можем просто использовать `()', чтобы ввести только что экспортированный TMPDIR в оболочку в Android 10.
_TMPDIR="$DATA_DIR/tmp"
if [ "$_TMPDIR" != "$TMPDIR" ] ; then
export TMPDIR="$_TMPDIR"
mkdir -p "$TMPDIR"
/system/bin/sh "$0" "$@"
exit "$?"
fi
export TMPDIR
mkdir -p "$TMPDIR"

trap 'exit 1' INT HUP QUIT TERM ALRM USR1

TERMSH="$LIB_DIR/libtermsh.so"

exit_with() {
echo "$@" >&2
exit 1
}

# === Локальный ===
if [ -z "$LANG" ] ; then
  export LANG='en_US.UTF-8'
else
  case "$LANG" in
    *.utf*|*.UTF*) ;;
    *) export LANG="${LANG%.*}.UTF-8" ;;
  esac
fi
# ===        ===

NI= # Не интерактивный
UP= # Плагин Essentials: принудительно/нет
while true ; do
case "$1" in
--) shift ; break ;;
-a) shift ; NI=1 ;;
-d) shift ; UP='no' ;;
-e) shift ; UP='force' ;;
-*) exit_with "Bad argument: $1" ;;
*) break ;;
esac
done

DISTRO="$1"
RELEASE="$2"
NAME="${3:-"linuxcontainers-$DISTRO-$RELEASE"}"
REG_USER="${REG_USER:-my_acct}"
FAV_SHELL="${FAV_SHELL:-/bin/bash}"
PROOT="${PROOT:-'$DATA_DIR/root/bin/proot'}"
PROOT_USERLAND="${PROOT:-'$DATA_DIR/root/bin/proot-userland'}"
ESSENTIALS="${ESSENTIALS_PKG:-green_green_avk.anothertermshellplugin_android10essentials}"

# В этом разделе проверяется, предоставлены ли необходимые аргументы командной строки,
#  в противном случае скрипт показывает использование и завершает работу.
if [ -z "$1" -o -z "$2" ] ; then
show_usage
exit 1
fi

# В этом разделе определена функция find_prefix, которая ищет совпадающую строку
# во входном потоке и возвращает совпавшую строку, если она найдена.

find_prefix() { # В старых Android нет `grep'.
local L
while read -r L ; do
case $L in
$1*) echo "$L" ; return 0 ;;
esac
done
return 1
}

# В этом разделе определена функция prompt, которая отображает 
# подсказку со значением по умолчанию, считывает ввод пользователя и присваивает введенное значение переменной.

prompt() {
echo -en "\e[1m$1 [\e[0m$2\e[1m]:\e[0m "
local _V
read _V
_V="${_V:-"$2"}"
eval "$3=${_V@Q}" # Оболочка по умолчанию не может `typeset -g' до Android 8.
}

# В этом разделе определена функция to_uname_arch, которая сопоставляет
# имена архитектур процессоров Android с соответствующими архитектурами uname.

to_uname_arch() {
case "$1" in
armeabi-v7a) echo armv7a ;;
arm64-v8a) echo aarch64 ;;
x86) echo i686 ;;
amd64) echo x86_64 ;;
*) echo "$1" ;;
esac
}

# функция validate_arch, которая проверяет, действительно ли
# заданное имя архитектуры, и возвращает имя архитектуры, если оно действительно.

validate_arch() {
case "$1" in
armv7a|aarch64|i686|amd64) echo $1 ; return 0 ;;
*) return 1 ;;
esac
}

#  функция validate_dir, которая проверяет, является ли 
#  заданный каталог действительным, и возвращает true, если он действителен.

validate_dir() { [ -d "$1" -a -r "$1" -a -w "$1" -a -x "$1" ] ; }

#  устанавливает переменную PROOTS в значение "proots"
PROOTS='proots'

# и запрашивает у пользователя имя каталога установки, если переменная NI не определена.
if [ -z "$NI" ] ; then
NAME="linuxcontainers-$DISTRO-$RELEASE"
echo
prompt "Installation subdir name $PROOTS/___" "$NAME" NAME
fi

# создает каталог установки, если он не существует
mkdir -p "$DATA_DIR/$PROOTS"
if ! validate_dir "$DATA_DIR/$PROOTS" ; then
echo -e "\nUnable to create \$DATA_DIR/$PROOTS"
exit 1
fi

NAME_C=1
NAME_S=
NAME_B="$NAME"

# Цикл до тех пор, пока не будет найдено уникальное имя для каталога rootfs
while true ; do
# Сгенерируйте новое имя, используя основание и суффикс
NAME="$NAME_B$NAME_S"
# Установите путь к каталогу rootfs
ROOTFS_DIR="$PROOTS/$NAME"
# Попытаться создать каталог rootfs и выйти из цикла в случае успеха
if mkdir "$DATA_DIR/$ROOTFS_DIR" >/dev/null 2>&1 ; then break ; fi
# Проверьте, не было ли установлено слишком много каталогов rootfs
if [ "$NAME_C" -gt 100 ] ; then
echo -e '\nSuspiciously many rootfses installed'
exit 1
fi
# Увеличиваем счетчик имен и обновляем суффикс
NAME_C="$(($NAME_C+1))"
NAME_S="-$NAME_C"
done

# Выведите фактическое имя каталога rootfs и инструкции по его удалению
echo -e "\nActual name: $NAME\n"
echo -e "To uninstall: run \`rm -rf \"\$DATA_DIR/$ROOTFS_DIR\"'\n"

# Установите путь к двоичному файлу minitar
MINITAR="$DATA_DIR/minitar"


echo 'Creating favorites...'
# Создайте сценарий для запуска внутри каталога rootfs
echo -e '#!/system/bin/sh\n\necho Installing... Try later.' > "$DATA_DIR/$ROOTFS_DIR/run"
# Сделайте скрипт исполняемым
chmod 755 "$DATA_DIR/$ROOTFS_DIR/run"

# Установите параметры терминала в зависимости от выбранного дистрибутива
case "$DISTRO" in
alpine) RUN_OPTS_TERM='xterm-xfree86' ;;
*) RUN_OPTS_TERM='' ;;
esac

# Установите команду для выполнения внутри каталога rootfs
RUN="/system/bin/sh \"\$DATA_DIR/$ROOTFS_DIR/run\""

# Создайте избранное для root и обычного пользователя, если он не находится в неинтерактивном режиме
if [ -z "$NI" ] ; then
# Установите параметры терминала для избранного
if [ -n "$RUN_OPTS_TERM" ] ; then
RUN_OPTS="&terminal_string=$RUN_OPTS_TERM"
else
RUN_OPTS=''
fi
# Кодировать команду для URI
UE_RUN="$("$TERMSH" uri-encode "$RUN")"
# Создать избранное для пользователя root
"$TERMSH" view \
-r 'green_green_avk.anotherterm.FavoriteEditorActivity' \
-u "local-terminal:/opts?execute=${UE_RUN}%200%3A0&name=$("$TERMSH" uri-encode "$NAME (root)")$RUN_OPTS"
# Создать избранное для обычного пользователя
"$TERMSH" view \
-r 'green_green_avk.anotherterm.FavoriteEditorActivity' \
-u "local-terminal:/opts?execute=${UE_RUN}&name=$("$TERMSH" uri-encode "$NAME")$RUN_OPTS"

else
# Запросить разрешение на управление избранным
# Установите ловушку для отзыва разрешения и снимите функцию ловушки, когда она будет завершена
"$TERMSH" request-permission favmgmt 'Installer is going to create a regular user and a root launching favs.' \
&& {
finally() { "$TERMSH" revoke-permission favmgmt ; trap - EXIT ; unset finally ; }
trap 'finally' EXIT
} || [ $? -eq 3 ]
# Установите параметры терминала для избранного
if [ -n "$RUN_OPTS_TERM" ] ; then
RUN_OPTS=(-t "$RUN_OPTS_TERM")
else
RUN_OPTS=()
fi
"$TERMSH" create-shell-favorite "${RUN_OPTS[@]}" "$NAME (root)" "$RUN 0:0" > /dev/null
"$TERMSH" create-shell-favorite "${RUN_OPTS[@]}" "$NAME" "$RUN" > /dev/null
if typeset -f finally >/dev/null 2>&1 ; then finally ; fi

fi

echo 'Done.'

# Проверьте архитектуру устройства, проверив вывод команды "uname -m".
# Если "uname -m" недоступен (например, на старых версиях Android), используйте первый ABI, указанный в MY_DEVICE_ABIS.
# Полученная архитектура хранится в переменной $ARCH.
# There is no uname on old Androids.
ARCH="$(validate_arch "$(uname -m 2>/dev/null)" || ( aa=($MY_DEVICE_ABIS) ; to_uname_arch "${aa[0]}" ))"

# Если версия Android SDK меньше 21, добавьте '-pre5' к варианту rootfs.
VARIANT=''
if [ -n "$MY_ANDROID_SDK" -a "$MY_ANDROID_SDK" -lt 21 ]
then
VARIANT='-pre5'
fi

# Преобразуйте имена архитектур, используемые контейнерами Linux, в имена, используемые minitar.
to_minitar_arch() {
case "$1" in
armv7a) echo armeabi-v7a ;;
aarch64) echo arm64-v8a ;;
i686) echo x86 ;;
amd64) echo x86_64 ;;
*) echo "$1" ;;
esac
}

# Преобразуйте имена архитектур, используемые контейнерами Linux, в имена архитектур, используемые интерактивными образами LXC.
to_lco_arch() {
case "$1" in
armv7a) echo armhf ;;
aarch64) echo arm64 ;;
i686) echo i386 ;;
x86_64) echo amd64 ;;
*) echo "$1" ;;
esac
}

# Получить URL-адрес tarball rootfs для указанной архитектуры и варианта из онлайн-репозитория образов LXC.
to_lco_link() {
local R
local P

# Загрузите индекс доступных образов с сайта LXC и найдите требуемый образ.
R="$( { "$TERMSH" cat 'https://images.linuxcontainers.org/meta/1.0/index-user' || exit_with 'Cannot download index from linuxcontainers.org' ;} \
| { find_prefix "$DISTRO;$RELEASE;$(to_lco_arch "$1");default;" || exit_with 'Cannot find specified rootfs' ;} )" || exit 1
# Извлеките URL tarball rootfs из информации об образе.
P="${R##*;}"
echo "https://images.linuxcontainers.org/$P/rootfs.tar.xz"
}

echo
echo "Arch: $ARCH"
echo "Variant: $VARIANT"
echo "Root FS: $DISTRO $RELEASE"
echo
# Если ROOTFS_URL не установлен 
# (например, если пользователь не указал URL rootfs), определите URL автоматически.
if [ -z "$ROOTFS_URL" ] ; then
ROOTFS_URL="$(to_lco_link "$ARCH")"
fi

echo "Source: $ROOTFS_URL"
echo

cd "$DATA_DIR"
(

OO="$([ -t 2 ] && echo --progress)"

# Используйте исполняемый файл minitar из плагина "essentials", если он доступен.
# В противном случае загрузите исполняемый файл minitar с GitHub.
# = Essentials =
if [ "$UP" != 'no' ] && E_MINITAR="$("$TERMSH" plugin "$ESSENTIALS" minitar)" 2>/dev/null
then MINITAR="$E_MINITAR"
elif [ "$UP" = 'force' ]
then exit_with 'No minitar in the essentials plugin found'
# ==============
else

# Загрузите исполняемый файл minitar с GitHub и сделайте его исполняемым.
# minitar - command line tar/gz/bzip2/xz unarchiver utility for Android
echo 'Getting minitar...'

"$TERMSH" cat $OO \
"https://raw.githubusercontent.com/green-green-avk/build-libarchive-minitar-android/master/prebuilt/$(to_minitar_arch "$ARCH")/minitar" \
> "$MINITAR"
chmod 755 "$MINITAR"

fi

# = Essentials =
# Этот раздел проверяет, не установлено ли для переменной UP значение «нет» и доступен ли плагин proot из пакета Essentials.
if [ "$UP" != 'no' ] && E_PROOT="$("$TERMSH" plugin "$ESSENTIALS" proot)" 2>/dev/null
then
  #Если оба условия верны, установите переменные PROOT и PROOT_USERLAND на пути к двоичным файлам proot.
  PROOT="\$(\"\$TERMSH\" plugin '$ESSENTIALS' proot)"
  PROOT_USERLAND="\$(\"\$TERMSH\" plugin '$ESSENTIALS' proot-userland)" || true
elif [ "$UP" = 'force' ]
then 
  #Если для UP установлено значение «force», выход с сообщением об ошибке
  exit_with 'No proot in the essentials plugin found'
# ==============
else
  # Если ни одно из вышеперечисленных условий не выполняется, загрузите и извлеките пакет proot с GitHub.
  echo 'Getting PRoot...'

  "$TERMSH" cat $OO \
  "https://raw.githubusercontent.com/green-green-avk/build-proot-android/master/packages/proot-android-$ARCH$VARIANT.tar.gz" \
  | "$MINITAR"
fi


# = Тест =
# В этом разделе проверяется, является ли версия Android SDK и версия SDK целевого приложения 29 или выше.
[ -n "$MY_ANDROID_SDK" -a "$MY_ANDROID_SDK" -ge 29 \
-a -n "$APP_TARGET_SDK" -a "$APP_TARGET_SDK" -ge 29 ] \
&& { 
  # Если оба условия верны, проверяем, может ли запуститься текущая версия proot или нет
  eval "$PROOT" --help > /dev/null 2>&1 || \
  # Если нет, выйдите с сообщением об ошибке, объясняющим, почему
  exit_with "$(
    echo 'Current PRoot version does not start.'
    echo "Your Android version is 10 (API 29) or higher and this Another Term version targets API $APP_TARGET_SDK."
    echo 'See https://green-green-avk.github.io/AnotherTerm-docs/local-shell-w-x.html#main_content'
  )" ; 
} || true
# ========

# Создание двух каталогов (root и tmp) 
# внутри каталога ROOTFS_DIR, а затем изменяют текущий 
# рабочий каталог на root

mkdir -p "$ROOTFS_DIR/root"
mkdir -p "$ROOTFS_DIR/tmp"
cd "$ROOTFS_DIR/root"

#Загрузите и извлеките корневую файловую систему Linux.
echo 'Getting Linux root FS...'

"$TERMSH" cat $OO "$ROOTFS_URL" | "$MINITAR" || echo 'Possibly URL was changed: recheck on the site.' >&2

#Запрашивать у пользователя обычное имя пользователя и предпочтительную оболочку
if [ -z "$NI" ] ; then
echo
echo -e '\e[1m/etc/passwd:\e[0m'
echo '\e[1m=======\e[0m'
cat etc/passwd
echo '\e[1m=======\e[0m'
prompt 'Regular user name' "$REG_USER" REG_USER
prompt 'Preferred shell' "$FAV_SHELL" FAV_SHELL
echo
fi

#Настройте сценарий запуска с параметрами конфигурации
echo 'Setting up run script...'

mkdir -p etc/proot
cat << EOF > etc/proot/run.cfg
# Main configuration

# Regular user name
USER=${REG_USER@Q}

# Preferred shell (fallback: /bin/sh)
SHELL=${FAV_SHELL@Q}

# =======

PROOT=$PROOT
PROOT_USERLAND=$PROOT_USERLAND

# Mostly for Android < 5 now. Feel free to adjust.
# Not recommended to set it >= '4.8.0' for kernels < '4.8.0'
# becouse of a random number generation API change at this point
# as it could break libopenssl random number generation routine.
_KERNEL_VERSION="$(uname -r 2>/dev/null || echo 0)"
if [ "\${_KERNEL_VERSION%%.*}" -lt 4 ] ; then
 PROOT_OPT_ARGS+=('-k' '4.0.0')
fi

# Android >= 9 может иметь ограничение на чтение
# on '/proc/version'.
cat /proc/version >/dev/null 2>&1 || {
 _PROC_VERSION="\$CFG_DIR/proc.version.cfg"
 { uname -a 2>/dev/null || echo 'Linux' ; } > "\$_PROC_VERSION"
 PROOT_OPT_ARGS+=('-b' "\$_PROC_VERSION:/proc/version")
}

# Общий каталог данных для приложения
PROOT_OPT_ARGS+=('-b' "\$SHARED_DATA_DIR:/mnt/shared")

# Раскомментируйте, чтобы управлять собственным каталогом личных данных
#  приложения Android.
#PROOT_OPT_ARGS+=('-b' '/data')

# =======
EOF
cat << EOF > etc/proot/run.rc
# Right before proot starting

if ! is_root
then
 PROOT_OPT_ARGS+=('--mute-setxid') # 'make' should be happy now...
fi
EOF
"$TERMSH" cat $OO \
'https://raw.githubusercontent.com/green-green-avk/AnotherTerm-scripts/master/assets/run-tpl' \
> etc/proot/run
chmod 755 etc/proot/run
rm -r ../run 2>/dev/null || true # Jelly Bean не имеет опции `-f' (по крайней мере, API 16).
ln -s root/etc/proot/run ../run # KitKat может использовать только `ln -s'.


echo 'Configuring...'

cat << EOF > bin/termsh
#!/bin/sh

unset LD_PRELOAD
unset LD_LIBRARY_PATH
/bin/_termsh "\$@"
EOF

chmod 700 bin/termsh

rm -r etc/resolv.conf 2>/dev/null || true # Бесплатный Фокус
cat << EOF > etc/resolv.conf
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

#Настройте среду с локалью и настройками PS1
cat << EOF > etc/profile.d/locale.sh
if [ -f /etc/default/locale ]
then
. /etc/default/locale
export LANG
fi
EOF
cat << EOF > etc/profile.d/ps.sh
PS1='\[\e[32m\]\u\[\e[33m\]@\[\e[32m\]\h\[\e[33m\]:\[\e[32m\]\w\[\e[33m\]\\$\[\e[0m\] '
PS2='\[\e[33m\]>\[\e[0m\] '
EOF

# Здесь нет ни adduser, ни useradd...
# Создать учетную запись пользователя с указанным именем пользователя и оболочкой
# и добавьте эту учетную запись пользователя в файл `/etc/passwd`
cp -a etc/skel home/$REG_USER 2>/dev/null || mkdir -p home/$REG_USER
echo \
"$REG_USER:x:$USER_ID:$USER_ID:guest:/home/$REG_USER:$FAV_SHELL" \
>> etc/passwd
)


echo -e '\nDone!\n'
