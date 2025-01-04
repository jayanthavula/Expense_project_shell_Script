#!/bin/bash
#This script is to install Mysql and start its services

USERID=$UID
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1)
TIME_STAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIME_STAMP

function CHECK_ROOT
{
if [ $USERID -ne 0 ]
then
   echo -e "$R Please run script with Sudo access"
fi
}

function VALIDATE
{
    if [ $1 -ne 0 ]
    then
       echo -e "$2 ... $R FAILURE $N"
       exit 1
    else
       echo  -e "$2 .. $G SUCCESS $N"
    fi
}

echo "Script start executing at: $TIME_STAMP" &>>$LOG_FILE_NAME

#Function call
CHECK_ROOT

dnf install mysql-server -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing MYSQL server"

systemctl start mysql-server $LOG_FILE_NAME
VALIDATE $? "Starting MYSQL server"

mysql -h mysql.daws82s.online -u root -pExpenseApp@1 -e 'show databases;' &>>$LOG_FILE_NAME

if [ $? -ne 0 ]
then
    echo "MYSQL Root password not setup" &>>$LOG_FILE_NAME
    mysql_secure_installation --set-root-pass ExpenseApp@1
    VALIDATE $1 "Setting Root Password"
else
    echo -e "MYSQL ROOT Password already setup.. $Y SKIPPING $N"
fi        
