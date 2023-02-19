$__IPv4_REGEXP = "^((25[0-5]|(2[0-4]|1[0-9]|[1-9]|)[0-9])(\.(?!$)|$)){4}$"
$__PORT_REGEXP = "^[0-6]\d{0,4}$"
$__SSH_FOLDER = "$HOME\.ssh"
$__SSH_KEYS_FOLDER = "$__SSH_FOLDER\keys"
$__SSH_CONFIG_FILE = "$__SSH_FOLDER\config"
$__SSH_CONFIG_CONTENTS = Get-Content $__SSH_CONFIG_FILE

function Read-Host-Advanced {
	param (
		[string]$Message,
		[string]$DefaultValue,
		[string]$ErrorMessage,
		[string]$RegExp,
		[switch]$Masked
	)
	
	$DefaultValueText = $DefaultValue ? $DefaultValue : "ОБЯЗАТЕЛЬНО"
	if (!$ErrorMessage) {
		$ErrorMessage = ""
		if (!$DefaultValue) {
			$ErrorMessage += "Это поле является обязательным для заполнения. "
		}
		if ($RegExp) {
			$ErrorMessage += "Введённые данные не соответствуют требуемому формату. "
		}
	}
	
	while (1) {
		$Read = Read-Host "$Message [$DefaultValueText]" -MaskInput:$Masked.IsPresent
		if (!$Read -and $DefaultValue) {
			$Read = $DefaultValue
		}
		if (!$Read -or ($RegExp -and !($Read -match $RegExp))) {
			Write-Host ("ОШИБКА: " + $ErrorMessage) -ForegroundColor Red
		} else {
			break
		}
	}
	$Read
}

## 

while (1) {
	$__HOSTNAME = Read-Host-Advanced "Название сервера"
	$__SSH_PRIVATE_KEY_FILE = $__SSH_KEYS_FOLDER + "\" + $__HOSTNAME + "_rsa"
	$__SSH_PUBLIC_KEY_FILE = $__SSH_PRIVATE_KEY_FILE + ".pub"
	if (($__SSH_CONFIG_CONTENTS -like "*Host $__HOSTNAME*") -or (Test-Path -Path $__SSH_PRIVATE_KEY_FILE -PathType Leaf)) {
		Write-Host "ОШИБКА: Сервер c таким названием уже существует" -ForegroundColor Red
	} else {
		break
	}
}

##

if (!(Test-Path -Path $__SSH_KEYS_FOLDER -PathType Container)) {
	mkdir $__SSH_KEYS_FOLDER
}
ssh-keygen -t rsa -b 4096 -f $__SSH_PRIVATE_KEY_FILE -P ""

$__IPv4ADDRESS = Read-Host-Advanced "IPv4 адрес" -ErrorMessage "Некорректный IPv4 адрес." -RegExp $__IPv4_REGEXP
$__PORT = Read-Host-Advanced "Порт" -DefaultValue 22 -ErrorMessage "Некорректный порт." -RegExp $__PORT_REGEXP
$__USER = Read-Host-Advanced "Имя пользователя" -DefaultValue "root"

##

Get-Content $__SSH_PUBLIC_KEY_FILE | ssh "$__USER@$__IPv4ADDRESS" -p $__PORT "cat >> .ssh/authorized_keys"

$__SSH_CONFIG_APPEND = "`n`nHost $__HOSTNAME
  HostName $__IPv4ADDRESS
  Port $__PORT
  User $__USER
  IdentityFile `"$__SSH_PRIVATE_KEY_FILE`""

Add-Content $__SSH_CONFIG_FILE $__SSH_CONFIG_APPEND