#!bin/bash
read -p "Comment: " comment
read -p "Name: " name
pwd_output=$(pwd)

#Comment this out if you want.
echo "---RESPONSE TEST---"
echo $comment
echo $name
echo $pwd_output

sed -i -e 's/}//g' ~/goto.sh
cat >> ~/goto.sh << EOF
	#$comment
	if [ "\$1" = "$name" ]
	then
		cd "$pwd_output"
	fi
}
EOF
