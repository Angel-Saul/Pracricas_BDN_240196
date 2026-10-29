import { createServer } from 'node:http';
import { createReadStream, statSync } from 'node:fs';
import { extname, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const root=resolve(fileURLToPath(new URL('.',import.meta.url)));
const backup=resolve(root,'../backups/240196_13.10.26.sql');
const mime={'.html':'text/html; charset=utf-8','.css':'text/css; charset=utf-8','.js':'text/javascript; charset=utf-8','.json':'application/json; charset=utf-8','.sql':'text/plain; charset=utf-8','.svg':'image/svg+xml'};
const server=createServer((req,res)=>{try{const pathname=decodeURIComponent(new URL(req.url,'http://localhost').pathname);let file=pathname==='/backups/240196_13.10.26.sql'?backup:resolve(root,`.${pathname}`);if(pathname==='/'||pathname==='/index.html')file=resolve(root,'index.html');if(file!==root&&!file.startsWith(root+sep)&&file!==backup){res.writeHead(403);res.end('Forbidden');return}const stat=statSync(file);if(!stat.isFile()){res.writeHead(404);res.end('Not found');return}res.writeHead(200,{'Content-Type':mime[extname(file)]||'application/octet-stream','Content-Length':stat.size,'X-Content-Type-Options':'nosniff','Cache-Control':'no-store'});createReadStream(file).pipe(res)}catch{res.writeHead(404,{'Content-Type':'text/plain; charset=utf-8'});res.end('No se encontró el recurso solicitado.')}});
const port=Number(process.env.PORT)||4173;server.listen(port,'127.0.0.1',()=>console.log(`Atlas EER: http://127.0.0.1:${port}`));
