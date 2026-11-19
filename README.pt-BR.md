<div align="center">

<a href="https://claper.co">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="priv/static/images/logo-large.svg" />
    <source media="(prefers-color-scheme: light)" srcset="priv/static/images/logo-large-black.svg" />
    <img src="priv/static/images/logo-large-black.svg" alt="Claper" height="72" />
  </picture>
</a>

### Transforme seus slides em uma conversa ao vivo.

Alternativa de código aberto e hospedagem própria ao Mentimeter, Slido e Wooclap.<br />
Adicione **perguntas e respostas**, **enquetes**, **questionários**, **formulários**, **legendas ao vivo** e **reações** aos seus slides.<br />
O público participa pelo celular, sem instalar aplicativo ou criar conta.

<p>
  <a href="https://app.claper.co/users/log_in"><strong>Experimentar gratuitamente</strong></a> ·
  <a href="https://docs.claper.co/self-hosting/quick-start.html"><strong>Hospedar por conta própria</strong></a> ·
  <a href="https://docs.claper.co"><strong>Documentação</strong></a> ·
  <a href="https://claper.co"><strong>Site</strong></a> ·
  <a href="https://community.claper.co"><strong>Comunidade</strong></a>
</p>

<p>
  <a href="https://github.com/ClaperCo/Claper/releases/latest"><img alt="Última versão" src="https://img.shields.io/github/v/release/ClaperCo/Claper?style=flat-square&color=8b5cf6" /></a>
  <a href="https://github.com/ClaperCo/Claper/actions/workflows/elixir.yml"><img alt="Integração contínua" src="https://img.shields.io/github/actions/workflow/status/ClaperCo/Claper/elixir.yml?branch=dev&style=flat-square&label=CI" /></a>
  <a href="https://github.com/ClaperCo/Claper/pkgs/container/claper"><img alt="Imagem Docker" src="https://img.shields.io/badge/docker-ghcr.io-2496ED?style=flat-square&logo=docker&logoColor=white" /></a>
  <a href="LICENSE.txt"><img alt="Licença AGPL-3.0" src="https://img.shields.io/github/license/ClaperCo/Claper?style=flat-square&color=6b7280" /></a>
</p>

</div>

<p align="center">
  <a href="https://claper.co">
    <img src=".github/assets/claper-preview.png" alt="Gerenciamento de evento, apresentação e interações da plateia" width="900" />
  </a>
</p>

<p align="center">
  <sub>O Claper é utilizado por milhares de apresentadores em organizações como CERN, Red Hat, KU Leuven, TU München e Deutsche Telekom (<a href="https://claper.co">claper.co</a>).</sub>
</p>

---

## Como começar

O código é o mesmo, mas você pode utilizar o serviço na nuvem do Claper ou instalar em seu próprio servidor.

| | **Claper Cloud** | **Hospedagem própria** |
|---|---|---|
| **Configuração** | Crie uma conta e comece | Instale com Docker Compose |
| **Preço** | Gratuito para até 10 participantes, depois [cobrança por evento](https://claper.co/#pricing) | Software gratuito, sem limite de participantes definido pela licença |
| **Dados** | Hospedados na União Europeia | Permanecem em seu servidor |
| **Atualizações** | Realizadas pela equipe do Claper | Você decide quando atualizar |
| | [**Experimentar na nuvem**](https://app.claper.co/users/log_in) | [**Instalar em servidor próprio**](#instalação-da-versão-traduzida-para-português-brasileiro) |

## Como funciona

1. **Envie a apresentação.** Utilize PDF, PPT ou PPTX, sem precisar reconstruir os slides.
2. **Adicione interações.** Vincule enquetes, questionários, formulários, conteúdo web e legendas aos slides.
3. **Compartilhe o código.** O público lê o QR Code ou digita o código do evento no celular.
4. **Apresente.** Perguntas, respostas e reações são recebidas em tempo real.
5. **Consulte os resultados.** Exporte mensagens, resultados e transcrições em CSV.

## Funcionalidades

### Perguntas, mensagens e moderação

- A plateia pode enviar perguntas e comentários com nome ou anonimamente.
- O moderador pode ordenar perguntas por popularidade, destacar mensagens e responder.
- É possível decidir quais mensagens aparecem no telão.
- Há opções para excluir mensagens, bloquear participantes e exibir somente mensagens fixadas.

### Enquetes, questionários e formulários

- Enquetes ao vivo, com resultados exibidos nos slides.
- Questionários com pontuação e respostas corretas.
- Formulários para recolher perguntas e outras informações estruturadas.
- Reações ao vivo durante a apresentação.

### Legendas e transcrição

- Transcrição de áudio em tempo real.
- Registro e exportação das transcrições.
- Integração com a Mistral, usando uma chave de API própria.

### Apresentações e gerenciamento

- Telas separadas de apresentação e gerenciamento, sincronizadas em tempo real.
- Possibilidade de incorporar YouTube, Vimeo, Canva, Google Slides e conteúdo web compatível.
- Navegação pelo teclado e organização dos itens por arrastar e soltar.
- Colaboração com facilitadores autorizados.

### Ensino e plataformas LMS

- Integração LTI 1.3 com Moodle e outras plataformas de ensino compatíveis.
- Envio de pontuações para o registro de notas da plataforma de ensino.
- Exportação de questionários em formato QTI.
- Nos resultados CSV, a pontuação exige selecionar todas as alternativas corretas e nenhuma incorreta, seguindo a lógica do programa.

### Recursos para organizações

- Login único (SSO) com provedores OpenID Connect.
- Painel administrativo para usuários, funções, eventos, provedores OIDC e registros de auditoria.
- Armazenamento local ou compatível com S3; envio de e-mails por SMTP ou Postmark.
- Imagem Docker oficial.
- Tradução da interface para português brasileiro neste fork, além dos idiomas mantidos do projeto original.

## Por que utilizar o Claper?

- **Controle dos dados.** Com hospedagem própria, perguntas e votações ficam na infraestrutura escolhida pelo operador.
- **Aproveitamento dos slides.** Apresente documentos PDF e PowerPoint existentes.
- **Sem cobrança por participante na instalação própria.** Os recursos do servidor é que determinam a capacidade real.
- **Código aberto.** O projeto utiliza a licença AGPL-3.0.
- **Atualização em tempo real.** Desenvolvido com Elixir e Phoenix LiveView para aplicações com conexões simultâneas.

Comparativos oficiais do Claper: [Slido](https://claper.co/blog/claper-vs-slido), [Mentimeter](https://claper.co/blog/claper-vs-mentimeter), [Wooclap](https://claper.co/blog/claper-vs-wooclap) e [AhaSlides](https://claper.co/blog/claper-vs-ahaslides).

## Instalação da versão traduzida para português brasileiro

**Requisito:** Docker e Docker Compose instalados.

Este fork contém traduções próprias. O `docker-compose.yml` original usa uma imagem pronta do Claper oficial, que **não inclui automaticamente as alterações deste fork**. Para compilar a versão em português brasileiro, use o arquivo complementar `docker-compose.pt-br.yml`.

```bash
git clone https://github.com/nandofmike/quest.git
cd quest
cp .env.sample .env

# Gere uma chave secreta exclusiva; guarde-a com segurança.
sed -i.bak "s|^SECRET_KEY_BASE=.*|SECRET_KEY_BASE=$(openssl rand -base64 48)|" .env

docker compose -f docker-compose.yml -f docker-compose.pt-br.yml up -d --build
```

Acesse <http://localhost:4000> para testar localmente.

A instalação original cria uma conta administrativa inicial:

| E-mail | Senha inicial |
|---|---|
| `admin@claper.co` | `claper` |

**Segurança:** altere imediatamente a senha padrão, substitua a senha de exemplo do PostgreSQL e configure o `BASE_URL` para o endereço real antes de disponibilizar o serviço na internet. Utilize HTTPS e um proxy reverso. As instruções oficiais de SSL estão na [documentação de instalação](https://docs.claper.co/self-hosting/quick-start.html#ssl-with-traefik).

Para a interface brasileira, a configuração do projeto define `pt_BR` como idioma padrão. O navegador configurado em `pt-BR` também é reconhecido e o idioma pode ser selecionado nas preferências da conta. Se você definir manualmente `LANGUAGES` no `.env`, inclua `pt_BR` na lista.

A compilação da imagem local pode consumir recursos consideráveis do servidor. O processo de instalação e a compatibilidade com uma VPS específica precisam ser testados.

**Importante:** os textos jurídicos originais do Claper (Termos e Política de Privacidade) mencionam `Claper.co`. Eles não devem ser reutilizados como documentos jurídicos próprios de outra empresa sem revisão.

### Próximos passos

- [Configurações de hospedagem](https://docs.claper.co/self-hosting/configuration.html)
- [Login único (OIDC)](https://docs.claper.co/integration/oidc.html)
- [Integração com plataformas de ensino (LTI 1.3)](https://docs.claper.co/integration/lti.html)
- [Atualizações](https://docs.claper.co/self-hosting/updating.html)

## Tecnologias utilizadas

[![Elixir][Elixir]][Elixir-url] [![Phoenix][Phoenix]][Phoenix-url] [![PostgreSQL][PostgreSQL]][PostgreSQL-url] [![Tailwind][Tailwind]][Tailwind-url]

Phoenix LiveView mantém a interface sincronizada em tempo real; PostgreSQL armazena os dados; Oban gerencia tarefas em segundo plano.

## Como contribuir

Contribuições com correções de erros, funcionalidades, documentação e traduções são bem-vindas.

1. Crie uma cópia do repositório (fork) e uma branch a partir de `dev`.
2. Configure o ambiente seguindo o [guia de desenvolvimento](https://docs.claper.co/self-hosting/development.html).
3. Abra uma solicitação de alteração (pull request) para a branch `dev`.

Leia também [CONTRIBUTING.md](CONTRIBUTING.md) e consulte as [questões abertas](https://github.com/ClaperCo/Claper/issues) ou o [fórum da comunidade](https://community.claper.co).

## Comunidade e suporte

- [Comunidade](https://community.claper.co): dúvidas, ideias e ajuda.
- [GitHub Issues](https://github.com/ClaperCo/Claper/issues): problemas e pedidos de funcionalidades.
- [Documentação](https://docs.claper.co): orientações de uso e instalação.
- [Fundador no X](https://x.com/alxlion_).
- [Política de segurança](https://claper.co/security): para relatar vulnerabilidades sem publicá-las.

## Licença

Claper utiliza a [GNU Affero General Public License versão 3.0](LICENSE.txt).

<!-- LINKS PARA ÍCONES -->

[Elixir]: https://img.shields.io/badge/Elixir-4B275F?style=for-the-badge&logo=elixir&logoColor=white
[Elixir-url]: https://elixir-lang.org/
[Phoenix]: https://img.shields.io/badge/Phoenix-FD4F00?style=for-the-badge&logo=phoenixframework&logoColor=white
[Phoenix-url]: https://www.phoenixframework.org/
[PostgreSQL]: https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white
[PostgreSQL-url]: https://www.postgresql.org/
[Tailwind]: https://img.shields.io/badge/Tailwind-06B6D4?style=for-the-badge&logo=tailwindcss&logoColor=white
[Tailwind-url]: https://tailwindcss.com/
