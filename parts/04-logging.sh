error() {
	(>&2 echo -e "\e[48;5;09m$@\e[m")
}

warning() {
	(>&2 echo -e "\e[48;5;214m$@\e[m")
}

success() {
	echo -e "\e[38;5;40m$@\e[m"
}
