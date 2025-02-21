___INFO___

{
  "type": "MACRO",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Google Sheets Reader",
  "description": "Read data from Google Sheets",
  "containerContexts": [
    "SERVER"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "RADIO",
    "name": "type",
    "displayName": "Type",
    "radioItems": [
      {
        "value": "cell",
        "displayValue": "Read Cell",
        "subParams": [],
        "help": "Returns value from google sheet cell"
      },
      {
        "value": "range",
        "subParams": [],
        "displayValue": "Read Range",
        "help": "Returns arrays from google sheet cell range."
      },
      {
        "value": "object",
        "displayValue": "Read Columns as Object",
        "help": "Add a range that includes two columns. Variable returns an object that consists of these two columns. The first column will be used as a name, and the second column will be used as a correspondent value."
      }
    ],
    "simpleValueType": true,
    "defaultValue": "cell"
  },
  {
    "type": "TEXT",
    "name": "cell",
    "displayName": "Cell",
    "simpleValueType": true,
    "defaultValue": "A1",
    "enablingConditions": [
      {
        "paramName": "type",
        "paramValue": "cell",
        "type": "EQUALS"
      }
    ],
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "range",
    "displayName": "Range",
    "simpleValueType": true,
    "defaultValue": "A1:C1",
    "enablingConditions": [
      {
        "paramName": "type",
        "paramValue": "range",
        "type": "EQUALS"
      },
      {
        "paramName": "type",
        "paramValue": "object",
        "type": "EQUALS"
      }
    ],
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "url",
    "displayName": "Spreadsheet URL",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ],
    "valueHint": "https://docs.google.com/spreadsheets/d/123456789/edit?"
  },
  {
    "type": "GROUP",
    "name": "authGropu",
    "displayName": "Authentication Credentials",
    "groupStyle": "NO_ZIPPY",
    "subParams": [
      {
        "type": "RADIO",
        "name": "authFlow",
        "displayName": "Type",
        "radioItems": [
          {
            "value": "stape",
            "displayValue": "Stape Google Connection",
            "help": "Learn how to setup Stape Google Sheet Connection \u003ca href\u003d\"https://app.stape.io/container/\" target\u003d\"_blank\"\u003ehere\u003c/a\u003e"
          },
          {
            "value": "own",
            "displayValue": "Own Google Credentials",
            "help": "Uses Application Default Credentials to automatically find credentials from the server environment. \u003ca href\u003d\"https://cloud.google.com/docs/authentication/application-default-credentials\"\u003ehttps://cloud.google.com/docs/authentication/application-default-credentials\u003c/a\u003e"
          }
        ],
        "simpleValueType": true,
        "defaultValue": "stape"
      }
    ]
  }
]


___SANDBOXED_JS_FOR_SERVER___

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


___SERVER_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "send_http",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedUrls",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "urls",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "https://oauth2.googleapis.com/"
              },
              {
                "type": 1,
                "string": "https://content-sheets.googleapis.com/"
              },
              {
                "type": 1,
                "string": "https://*.stape.io/*"
              },
              {
                "type": 1,
                "string": "https://*.stape.net/*"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "use_google_credentials",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedScopes",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "https://www.googleapis.com/auth/spreadsheets"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_request",
        "versionId": "1"
      },
      "param": [
        {
          "key": "headerWhitelist",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "headerName"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "x-gtm-identifier"
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "headerName"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "x-gtm-default-domain"
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "headerName"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "x-gtm-api-key"
                  }
                ]
              }
            ]
          }
        },
        {
          "key": "headersAllowed",
          "value": {
            "type": 8,
            "boolean": true
          }
        },
        {
          "key": "requestAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "headerAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "queryParameterAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios: []


___NOTES___

Created on 04/04/2022, 15:59:37


