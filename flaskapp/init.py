from flask import Flask, render_template, request, redirect
from flask_mysqldb import MySQL
import yaml
import hashlib, binascii, os

app = Flask(__name__)

db = yaml.load(open('/var/www/html/flaskapp/db.yaml'))

app.config['MYSQL_HOST'] = db['mysql_host']
app.config['MYSQL_USER'] = db['mysql_user']
app.config['MYSQL_PASSWORD'] = db['mysql_password']
app.config['MYSQL_DB'] = db['mysql_db']

mysql = MySQL(app)

@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':

        user_details = request.form
        username = user_details['username']
        password = user_details['password']

        if len(username) < 5 or len(password) < 5:
            return render_template('index.html')


        cur = mysql.connection.cursor()
        result_value = cur.execute("SELECT username FROM users")
        list_usernames = cur.fetchall()

        for x in list_usernames:
            if username in x:
                cur = mysql.connection.cursor()
                result_value = cur.execute("SELECT password_hash FROM users where username = " + "'" + username + "'")
                hash_from_sql = cur.fetchmany(1)

                for row in hash_from_sql:
                    pwdhash = row[0]

                if verify_password(str(pwdhash), password) == True:
                    return render_template('new_login_succes.html')
                else:
                    return render_template('new_login_fail.html')


        password_hash = hash_password(password)

        cur = mysql.connection.cursor()
        cur.execute("INSERT INTO users (username, password_hash) VALUES (%s, %s)",(username, password_hash))
        mysql.connection.commit()
        cur.close()
        return render_template('new_user.html')
    return render_template('index.html')

def hash_password(password):
    """Hash a password for storing."""
    salt = hashlib.sha256(os.urandom(60)).hexdigest().encode('ascii')
    pwdhash = hashlib.pbkdf2_hmac('sha512', password.encode('utf-8'),
                                salt, 100000)
    pwdhash = binascii.hexlify(pwdhash)

    return (salt + pwdhash).decode('ascii')

def verify_password(stored_password, provided_password):
    """Verify a stored password against one provided by user"""
    salt = stored_password[:64]
    stored_password = stored_password[64:]
    pwdhash = hashlib.pbkdf2_hmac('sha512',
                                  provided_password.encode('utf-8'),
                                  salt.encode('ascii'),
                                  100000)
    pwdhash = binascii.hexlify(pwdhash).decode('ascii')

    return pwdhash == stored_password
