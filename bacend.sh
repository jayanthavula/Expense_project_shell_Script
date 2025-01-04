#!/bin/bash
#This script to Backend services to install Nodejs and start services

USERID=$UID

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[m0"

LOGS_FOLDER="/var/log/expense-logs"
LOG_FILE=$(echo $0 | cut -d "." -f1 )
TIME_STAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIME_STAMP.log"

function CHECK_ROOT
{
    if [ $USERID -ne 0 ]
    then
        echo "Please execute script with Sudo access"
        exit 1
    fi    
}

function VALIDATE
{
   if [ $1 -ne 0 ]
   then
        echo -e "$2 ... $R FAILURE $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi    
}

echo "Script started executing at $TIME_STAMP" &>>$LOG_FILE_NAME
CHECK_ROOT

dnf module disable nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Disabled nodejs module"

dnf module enable nodejs:20 -y &>>$LOG_FILE_NAME
VALIDATE $? "enable nodejs module with version 20"

dnf install nodejs -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing nodejs"

id expense &>>$LOG_FILE_NAME
if [ $? -ne 0 ]
then
    useradd expense &>>$LOG_FILE_NAME
    VALIDATE $? "Adding expense user"
else
    echo -e "expense user already exists ... $Y SKIPPING $N"
fi
rm -rf /app/
mkdir /app
VALIDATE $? "/app directory creation"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip
VALIDATE $? "Downloading backend"

cd /app
rm -rf /app/*

unzip /tmp/backend.zip &>>$LOG_FILE_NAME
VALIDATE $? "unzip backend"

npm install &>>$LOG_FILE_NAME
VALIDATE $? "Installing dependencies"

cp /home/ec2-user/Expense_project_shell_Script/backend.service /etc/systemd/system/backend.service

dnf install mysql -y &>>$LOG_FILE_NAME
VALIDATE $? "Installing MySQL Client"

mysql -h mysql.jaydevops.online -uroot -pExpenseApp@1 < /app/schema/backend.sql &>>$LOG_FILE_NAME
VALIDATE $? "Setting up the transactions schema and tables"

systemctl daemon-reload &>>$LOG_FILE_NAME
VALIDATE $? "Daemon Reload"

systemctl enable backend &>>$LOG_FILE_NAME
VALIDATE $? "Enabling backend"

systemctl restart backend &>>$LOG_FILE_NAME
VALIDATE $? "Starting Backend"