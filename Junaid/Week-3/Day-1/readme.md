# Postgres Setup on Fedora

## Install Postgres

- Open the terminal and hit the following commands:
  - sudo dnf install postgresql-server (install postgres)
  - sudo postgresql-setup --initdb (initialize a db cluster, you can then go to admin:///var/lib/pgsql in your file system to view it)
  - sudo systemctl start postgresql (start postgres server)
  - sudo systemctl enable postgresql (enable on launch)
  - sudo -i -u postgres psql (setup password)
  - ALTER USER postgres WITH PASSWORD 'your_secure_password'; (throw in this query and set your password)

## Install Pgadmin

- Open software app:
  - search up pgadmin, install the package from flathub
  - Fedora postgres is going to restrict local connections so you have to do a few more steps before this. open terminal and:
    - sudo nano /var/lib/pgsql/data/pg_hba.conf
    - Scroll in the nano editor to the ipv4 and ipv6 local connection configurations, the 4th column will say "Ident". Change that to "scram-sha-256"
    - just press ctrl+C and then ctrl+x to exit nano and then restart postgres with:
    - sudo systemctl restart postgresql
    - flatpak override org.pgadmin.pgAdmin4 --share=network
    - thats it, now you can go to pgadmin
  - Open pgadmin app and press "add new server"
    - write the server name in the General tab (mine is Local Fedora Server)
    - go to Connection tab and enter the following:
      - Host name/address: localhost
      - port: 5432
      - password: the same one you typed in the ALTER statement in the first step when setting password
      - press save

## Create Database

- just open pgadmin
- right click on Servers/<your server name, mine is Local Fedora Server>/Databases
- hover on Create, press Database (or just press alt+shift+N)
- name your database something
- press save
- your new db is created

## Create Tables

- in the new db you created (mine is called DummyDB). right click and select Query Tool
- write the sql to create the table (go to SQL-Files/create_table to view the sql code)
- press F5 to run the script
- you can view the new table you just made in the object explorer in pgadmin at DummyDB/Schemas/public/Tables

## Import CSV files

- first create the table schema (SQL-Files/create_superstore_table)
- then select the newly created table in the object explorer
- select tools from the top bar, and select import/export data
- select file and select csv and import, if you see any errors:
  - open the processes tab in pgadmin, click on the view details button and read the logs
  - fix the error with an alter statment (SQL-Files/alter_superstore_table)
  - try importing again, view the processes tab and the logs again, repeat until you have resolved all the errors
  - use a select count(*) from superstore to verify the import after its successful

## Execute SQL Queries

- Already did that several times before