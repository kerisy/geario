
import http.HttpServer;

void main(string[] args)
{
    auto server = new HttpServer;
    server.Listen(8080);
    server.Start();
}
