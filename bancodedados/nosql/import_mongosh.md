# Importação para MongoDB com `mongosh`

Siga este roteiro para carregar o dataset relacional no MongoDB:

1. **Certifique-se de que o servidor MongoDB (mongod) está em execução.**

2. **Abra o MongoDB Shell** (`mongosh`).  
   - Executando o binário diretamente (`mongosh.exe`) ou abrindo pelo MongoDB Compass.
   - Quando solicitado, pressione **Enter** para usar a conexão padrão `mongodb://localhost/`.

3. **Selecione o banco e, opcionalmente, limpe a coleção existente:**

   ```javascript
   use skillbridge
   db.recomendacoes.drop()
   ```

4. **Carregue o JSON salvo no diretório `nosql`:**

   ```javascript
   const fs = require('fs');
   const json = JSON.parse(
     fs.readFileSync('C:/Users/Afonso/Desktop/bancodedados/nosql/dataset.json', 'utf8')
   );
   ```

5. **Insira os documentos na coleção `recomendacoes`:**

   ```javascript
   db.recomendacoes.insertMany(json.usuarios);
   ```

6. **Valide a importação:**

   ```javascript
   db.recomendacoes.find().pretty();
   ```

7. **(Opcional) Visualize via MongoDB Compass:**  
   Abra o Compass, conecte-se ao host local e confira o banco `skillbridge` → coleção `recomendacoes`.

> Caso utilize outro caminho para o arquivo, ajuste o parâmetro do `fs.readFileSync`.


