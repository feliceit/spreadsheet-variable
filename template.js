const JSON = require('JSON');
const sendHttpRequest = require('sendHttpRequest');
const encodeUriComponent = require('encodeUriComponent');
const getGoogleAuth = require('getGoogleAuth');
const getRequestHeader = require('getRequestHeader');

const spreadsheetId = data.url.replace('https://docs.google.com/spreadsheets/d/', '').split('/')[0];
const requestUrl = getUrl();
const auth = getGoogleAuth({
    scopes: ['https://www.googleapis.com/auth/spreadsheets']
});

return sendGetRequest();

function sendGetRequest() {
    let params = {
        headers: {'Content-Type': 'application/json', }, 
        method: 'GET'
    };
    
    if (data.authFlow === 'own') {
        params.authorization = auth;
    }
    
    return sendHttpRequest(requestUrl, params).then(successResult => {
        let bodyParsed = JSON.parse(successResult.body);
        
        if (successResult.statusCode >= 200 && successResult.statusCode < 400) {
            if (data.type === 'cell') {
                return bodyParsed.values[0][0];
            }
            
            if (data.type === 'object') {
                // Ottiene le intestazioni dalla prima riga
                const headers = bodyParsed.values[0];
                
                // Crea un array di oggetti, uno per ogni riga (esclusa la prima riga delle intestazioni)
                const result = [];
                
                // Itera su ogni riga a partire dalla seconda
                for (let i = 1; i < bodyParsed.values.length; i++) {
                    const row = bodyParsed.values[i];
                    const obj = {};
                    
                    // Per ogni cella nella riga, utilizza l'intestazione corrispondente come chiave
                    for (let j = 0; j < headers.length; j++) {
                        // Se il valore nella posizione corrente esiste, assegnalo; altrimenti, usa una stringa vuota
                        obj[headers[j]] = j < row.length ? row[j] : '';
                    }
                    
                    result.push(obj);
                }
                
                return result;
            }
            
            return bodyParsed.values;
        } else {
            return '';
        }
    });
}

function getUrl() {
    if (data.authFlow === 'stape') {
        const containerIdentifier = getRequestHeader('x-gtm-identifier');
        const defaultDomain = getRequestHeader('x-gtm-default-domain');
        const containerApiKey = getRequestHeader('x-gtm-api-key');
      
        return (
          'https://' +
          enc(containerIdentifier) +
          '.' +
          enc(defaultDomain) +
          '/stape-api/' +
          enc(containerApiKey) +    
          '/v1/spreadsheet/auth-proxy?spreadsheetId=' + spreadsheetId +
          '&range=' + enc(data.type === 'cell' ? data.cell : data.range)
        );
    }
    
    return 'https://content-sheets.googleapis.com/v4/spreadsheets/'+spreadsheetId+'/values/'+enc(data.type === 'cell' ? data.cell : data.range);
}

function enc(data) {
    data = data || '';
    return encodeUriComponent(data);
}
