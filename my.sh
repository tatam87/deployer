mysql -uroot -pmegalink87 <<EOF
exit
EOF
normallogin=$?
sudo mysql
sudologin=$?

echo $normallogin
echo $sudologin

