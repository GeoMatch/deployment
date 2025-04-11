def lambda_handler(event, context):

   message = 'Hello {} !'.format(event['key1'])

   code = "world"
   message = 'Hello {} !'.format(code)
   return {
       'statusCode': 200,       
       'headers': {
            'Content-Type': 'text/html'
        }, 
        'body' : message
    }

