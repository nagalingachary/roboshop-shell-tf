#!/bin/bash

DATE=$(date +%F)
LOGSDIR=/tmp
# /home/centos/shellscript-logs/script-name-date.log
SCRIPT_NAME=$0
LOGFILE=$LOGSDIR/$0-$DATE.log
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"

if [ $USERID -ne 0 ];
then
    echo -e "$R ERROR:: Please run this script with root access $N"
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ];
    then
        echo -e "$2 ... $R FAILURE $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

yum install maven -y &>>$LOGFILE

VALIDATE $? "Installing Maven"

#once the user is created, if you run this script 2nd time
# this command will defnitely fail
# IMPROVEMENT: first check the user already exist or not, if not exist then create
USER_ROBOSHOP=$(id roboshop)
if [ $? -ne 0 ];
then 
    echo -e "$Y...USER roboshop is not present so creating one now..$N"
    useradd roboshop &>>$LOGFILE
else 
    echo -e "$G...USER roboshop is already present so  skipping now.$N"
fi

#checking the app directory created or not
VALIDATE_APP_DIR=$(cd /app)
#write a condition to check directory already exist or not
if [ $? -ne 0 ];
then 
    echo -e " $Y /app directory not there so creating one $N"
    mkdir /app &>>$LOGFILE   
else
    echo -e "$G /app directory already present so skipping ....$N" 
fi

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping.zip &>>$LOGFILE

VALIDATE $? "Downloading shipping artifact"

cd /app &>>$LOGFILE

VALIDATE $? "Moving to app directory"

unzip /tmp/shipping.zip &>>$LOGFILE

VALIDATE $? "Unzipping shipping"

mvn clean package &>>$LOGFILE

VALIDATE $? "packaging shipping app"

mv target/shipping-1.0.jar shipping.jar &>>$LOGFILE

VALIDATE $? "renaming shipping jar"

cp /home/centos/roboshop-shell/shipping.service /etc/systemd/system/shipping.service &>>$LOGFILE

VALIDATE $? "copying shipping service"

systemctl daemon-reload &>>$LOGFILE

VALIDATE $? "daemon-reload"

systemctl enable shipping  &>>$LOGFILE

VALIDATE $? "Enabling shipping"

systemctl start shipping &>>$LOGFILE

VALIDATE $? "Starting shipping"


yum install mysql -y  &>>$LOGFILE

VALIDATE $? "Installing MySQL client"

mysql -h mysql.devopscollab.tech -uroot -pRoboShop@1 < /app/schema/shipping.sql  &>>$LOGFILE

VALIDATE $? "Loaded countries and cities info"

systemctl restart shipping &>>$LOGFILE

VALIDATE $? "Restarting shipping"