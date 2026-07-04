import cgi, json, re, sqlite3
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
from urllib.parse import urlparse, parse_qs
from importer import import_pair
ROOT=Path(__file__).resolve().parents[1]; DB=Path(__file__).with_name('engage.db'); UPLOADS=Path(__file__).with_name('uploads')
class Handler(SimpleHTTPRequestHandler):
    def __init__(self,*args,**kwargs): super().__init__(*args,directory=str(ROOT),**kwargs)
    def send_json(self,data,status=200):
        body=json.dumps(data,ensure_ascii=False).encode(); self.send_response(status); self.send_header('Content-Type','application/json; charset=utf-8'); self.send_header('Access-Control-Allow-Origin','*'); self.send_header('Content-Length',str(len(body))); self.end_headers(); self.wfile.write(body)
    def do_GET(self):
        u=urlparse(self.path)
        if not u.path.startswith('/api/'): return super().do_GET()
        try:
            q=parse_qs(u.query); con=sqlite3.connect(DB); con.row_factory=sqlite3.Row
            if u.path=='/api/periods': data=[dict(r) for r in con.execute('SELECT account_owner,year,quarter,version,imported_at,engage_file,specialize_file FROM import_batches WHERE is_active=1 ORDER BY year DESC,quarter DESC,account_owner')]
            elif u.path=='/api/import-history': data=[dict(r) for r in con.execute('SELECT id,account_owner,year,quarter,version,status,is_active,imported_at,engage_file,specialize_file FROM import_batches ORDER BY imported_at DESC LIMIT 50')]
            elif u.path=='/api/partners':
                year=int(q.get('year',[0])[0]); quarter=int(q.get('quarter',[0])[0]); owner=q.get('owner',[''])[0]; sql='''SELECT p.canonical_name channel,ps.engagement_level level,ps.integrator_compliant integrator,ps.mssp_account,ps.mssp_compliant mssp,b.account_owner owner FROM import_batches b JOIN partner_snapshots ps ON ps.batch_id=b.id JOIN partners p ON p.id=ps.partner_id WHERE b.is_active=1 AND b.year=? AND b.quarter=?'''; params=[year,quarter]
                if owner: sql+=' AND b.account_owner=?'; params.append(owner)
                data=[dict(r) for r in con.execute(sql+' ORDER BY p.canonical_name',params)]
            elif u.path=='/api/specializations':
                year=int(q.get('year',[0])[0]); quarter=int(q.get('quarter',[0])[0]); owner=q.get('owner',[''])[0]; sql='''SELECT p.canonical_name channel,b.account_owner owner,s.sd_wan,s.sase,s.secure_networking_lan,s.cloud_security,s.secure_networking_firewall,s.security_operations,s.ot FROM import_batches b JOIN specialization_snapshots s ON s.batch_id=b.id JOIN partners p ON p.id=s.partner_id WHERE b.is_active=1 AND b.year=? AND b.quarter=?'''; params=[year,quarter]
                if owner: sql+=' AND b.account_owner=?'; params.append(owner)
                data=[dict(r) for r in con.execute(sql+' ORDER BY p.canonical_name',params)]
            else: con.close(); return self.send_json({'error':'Endpoint não encontrado'},404)
            con.close(); self.send_json(data)
        except Exception as e: self.send_json({'error':str(e)},500)
    def do_POST(self):
        path=urlparse(self.path).path
        if path not in {'/api/import','/api/import-delete'}: return self.send_json({'error':'Endpoint não encontrado'},404)
        try:
            if path=='/api/import-delete':
                form=cgi.FieldStorage(fp=self.rfile,headers=self.headers,environ={'REQUEST_METHOD':'POST','CONTENT_TYPE':self.headers.get('Content-Type',''),'CONTENT_LENGTH':self.headers.get('Content-Length','0')})
                batch_id=int(form.getfirst('batch_id','0')); con=sqlite3.connect(DB); con.execute('PRAGMA foreign_keys=ON'); row=con.execute('SELECT account_owner,year,quarter,is_active FROM import_batches WHERE id=?',(batch_id,)).fetchone()
                if not row: con.close(); raise ValueError('Importação não encontrada')
                owner,year,quarter,was_active=row; con.execute('DELETE FROM import_batches WHERE id=?',(batch_id,))
                if was_active:
                    previous=con.execute('SELECT id FROM import_batches WHERE account_owner=? AND year=? AND quarter=? ORDER BY version DESC LIMIT 1',(owner,year,quarter)).fetchone()
                    if previous: con.execute("UPDATE import_batches SET is_active=1,status='complete' WHERE id=?",(previous[0],))
                con.commit(); con.close(); return self.send_json({'ok':True})
            form=cgi.FieldStorage(fp=self.rfile,headers=self.headers,environ={'REQUEST_METHOD':'POST','CONTENT_TYPE':self.headers.get('Content-Type',''),'CONTENT_LENGTH':self.headers.get('Content-Length','0')})
            owner=str(form.getfirst('owner','')).strip(); year=int(form.getfirst('year','0')); quarter=int(form.getfirst('quarter','0'))
            if not owner or year<2020 or quarter not in range(1,5): raise ValueError('Account Owner, ano e quarter são obrigatórios')
            engage=form['engage']; specialize=form['specialize']
            if not engage.filename or not specialize.filename: raise ValueError('As duas planilhas são obrigatórias')
            if not engage.filename.lower().endswith('.xlsx') or not specialize.filename.lower().endswith('.xlsx'): raise ValueError('Envie arquivos no formato .xlsx')
            slug=re.sub(r'[^a-z0-9]+','-',owner.lower()).strip('-'); folder=UPLOADS/str(year)/f'Q{quarter}'/slug; folder.mkdir(parents=True,exist_ok=True)
            engage_path=folder/Path(engage.filename).name; specialize_path=folder/Path(specialize.filename).name
            engage_path.write_bytes(engage.file.read()); specialize_path.write_bytes(specialize.file.read())
            result=import_pair(DB,engage_path,specialize_path,owner,year,quarter); self.send_json({'ok':True,**result},201)
        except Exception as e: self.send_json({'ok':False,'error':str(e)},400)
if __name__=='__main__': ThreadingHTTPServer(('127.0.0.1',8767),Handler).serve_forever()


