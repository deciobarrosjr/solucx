import os
from flask import Flask, render_template, request

app = Flask(__name__)


@app.route('/')
def index():

#   Getting the environment variables from the OS for troubleshooting 
    db_user = os.environ.get('DB_USER', 'DB_USER: Not defined')
    db_pass = os.environ.get('DB_PASS', 'DB_PASS: Not defined')
    db_name = os.environ.get('DB_NAME', 'DB_NAME: Not defined')
    db_host = os.environ.get('DB_HOST', 'DB_HOST: Not defined')
    cloud_sql_connection_name = os.environ.get('CLOUD_SQL_CONNECTION_NAME', 'Not defined')

    return render_template('log_env.html', msg= 'Conteudo das var Env!', db_user= db_user, db_pass= db_pass, db_name= db_name, db_host= db_host, cloud_sql= cloud_sql_connection_name)



if __name__ == "__main__":
    app.run(debug=True,host='0.0.0.0',port=int(os.environ.get('PORT', 8080)))
