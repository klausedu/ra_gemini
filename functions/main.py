# functions/main.py
# Este é um código "dummy" (placeholder) para o deploy da Cloud Function

def hello_world(request):
    """
    Função HTTP de exemplo.
    Responde a um request HTTP com "Hello, World!" ou um nome, se fornecido.
    """
    request_json = request.get_json(silent=True)
    request_args = request.args

    if request_json and 'name' in request_json:
        name = request_json['name']
    elif request_args and 'name' in request_args:
        name = request_args['name']
    else:
        name = 'World'
        
    print(f"Função invocada. Respondendo 'Hello, {name}!'")
    
    return f'Hello, {name}!'