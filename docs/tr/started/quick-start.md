---
title: Hızlı Başlangıç
description: Stackvo ile ilk projenizi oluşturmak için adım adım kılavuz. Docker kurulumundan proje yapılandırmasına, hosts dosyası düzenlemeden tarayıcıda test etmeye kadar tüm süreç detaylı olarak anlatılmaktadır.
---

# Hızlı Başlangıç

Bu kılavuz, Stackvo ile ilk projenizi oluşturmanız için gereken tüm adımları detaylı olarak anlatmaktadır. Docker kurulumundan proje yapılandırmasına, hosts dosyası düzenlemeden tarayıcıda test etmeye kadar her şeyi adım adım öğreneceksiniz.

---

!!! warning "Kurulum Gerekli"
    Bu kılavuz **kurulumun tamamlandığını** varsayar. Henüz kurmadıysanız önce [Kurulum](../installation/index.md) sayfasını takip edin.

**Kurulum tamamlandıysa devam edin:**

---

## İlk Projenizi Oluşturun

### Laravel Projesi Örneği

#### 1. Proje Klasörünü Oluşturun

```bash
# Proje klasörü
mkdir -p projects/mylaravel/public

# İçine basit bir index.php ekleyin
cat > projects/mylaravel/public/index.php <<'EOF'
<?php
phpinfo();
EOF
```

#### 2. Proje Konfigürasyonu

```bash
# stackvo.json oluşturun
cat > projects/mylaravel/stackvo.json <<'EOF'
{
  "name": "mylaravel",
  "domain": "mylaravel.loc",
  "php": {
    "version": "8.2",
    "extensions": [
      "pdo",
      "pdo_mysql",
      "mbstring",
      "xml",
      "curl",
      "zip"
    ]
  },
  "server": "nginx",
  "document_root": "public"
}
EOF
```

#### 3. Hosts Dosyasına Ekleyin

```bash
# /etc/hosts (Linux/macOS) veya C:\Windows\System32\drivers\etc\hosts (Windows)
127.0.0.1  mylaravel.loc
```

#### 4. Projeyi Başlatın

```bash
# Konfigürasyonu yeniden üret
./stackvo.sh generate

# Container'ları yeniden başlat
./stackvo.sh restart

# Proje container'ını kontrol et
docker ps | grep mylaravel
```

#### 5. Tarayıcıda Açın

[https://mylaravel.loc](https://mylaravel.loc)

!!! success "İlk Projeniz Hazır!"
    PHP bilgi sayfasını görmelisiniz! 🎉