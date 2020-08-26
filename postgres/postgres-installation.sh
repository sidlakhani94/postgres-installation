#!/bin/bash
#Author: Siddharth Lakhani
#Description: Install and configure Postgres in CentOS 8

psql --version > /dev/null 2>&1
if [ $? -gt 1 ]; then

    #List Available Version of Postgresql in CentOS By Default.

    dnf module list postgresql

    read -p "Enter Version of Postgresql From Given List: " version
    read -sp "Super User Password: " PASS_SU
    echo ""
    read -p "Enter Port Number: " NEW_PORT

    #Install Postgresql

    echo "**********Start Installing Postgresql***********"
    sudo dnf module enable postgresql:$version -y
    sudo dnf install postgresql-server -y
    echo "*********Postgresql Installation Completed******"

    #Initializing Postgresql Databse Server

    echo "*********Initializing Postgresql Database*******"
    sudo postgresql-setup --initdb
    sudo systemctl start postgresql
    sudo systemctl enable postgresql

    #Creating New Role in Postgres

    # echo "********Creating Role of Postgresql************"

    # id $NEW_ROLE &> /dev/null
    # if [ $? -ne 0 ]; then
    #     sudo useradd $NEW_ROLE
    # else 
    #     echo "User $NEW_ROLE already Exists"
    # fi

    #Configuring Postgresql

    echo "*******Configuring Postgresql******************"
    sudo sed -i "s/ident/md5/g" /var/lib/pgsql/data/pg_hba.conf
    echo "host    all             all             0.0.0.0/0            md5" | sudo tee -a /var/lib/pgsql/data/pg_hba.conf &> /dev/null
    echo "listen_addresses = '*'" | sudo tee -a /var/lib/pgsql/data/postgresql.conf &> /dev/null

    Default_Port=$(sudo netstat -apn | grep tcp | grep postmaster | head -n 1 | awk '{print $4}' | sed 's/^.*://')
    if [ $Default_Port -ne $NEW_PORT ]; then
        echo "port = $NEW_PORT" | sudo tee -a /var/lib/pgsql/data/postgresql.conf &> /dev/null
        sudo firewall-cmd --permanent --add-port=$NEW_PORT/tcp
        sudo firewall-cmd --reload
        sudo semanage port -a -t postgresql_port_t -p tcp $NEW_PORT
        echo "Default Port of Postgresql Changed to $NEW_PORT"
    else
        echo "$NEW_PORT is Default Port of Postgresql"
    fi

    sudo systemctl restart postgresql

    #Changing Postgres User Password

    echo "********Changing Password of Postgres user Database**************"
    sudo -u postgres psql -U postgres -p $NEW_PORT -d postgres -c "alter user postgres with password '$PASS_SU';"
    echo "********Postgresql Installed and Confiugred Successfully*********"

else
    echo "*******Postgresql is already Installed**************************"
fi 