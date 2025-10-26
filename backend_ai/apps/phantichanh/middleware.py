# phantichanh/middleware.py
from django.utils.deprecation import MiddlewareMixin

class NoCacheMediaMiddleware(MiddlewareMixin):
    """
    Ngăn cache cho các file trong /media/
    """
    def process_response(self, request, response):
        if request.path.startswith('/media/'):
            response['Cache-Control'] = 'no-cache, no-store, must-revalidate, max-age=0'
            response['Pragma'] = 'no-cache'
            response['Expires'] = '0'
        return response