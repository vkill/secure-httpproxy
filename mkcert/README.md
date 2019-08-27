## Make cert

```
CAROOT=$(pwd) mkcert -install
CAROOT=$(pwd) mkcert proxy.lvh.me

cat proxy.lvh.me.pem rootCA.pem > ../nginx/cert/proxy.lvh.me.crt
cat proxy.lvh.me-key.pem > ../nginx/cert/proxy.lvh.me.key
```
