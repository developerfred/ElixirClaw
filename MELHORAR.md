Analisando o código com calma antes de responder:Vou analisar o código que já está no contexto para criar um roadmap honesto e priorizado.

Aqui está o roadmap, dividido em fases com justificativa técnica real para cada item:

---

## Fase 1 — Fundação (sem isso, nada mais importa)

**1. Testes reais**

O projeto vende confiabilidade mas `mix test` cobre apenas Protocol e Security. Os módulos mais críticos — Gateway, Node, Auth — não têm um único teste.

Prioridade mínima:
- `gateway_test.exs` com mocks do WebSocket (biblioteca `mox`)
- `node_test.exs` testando cada capability com stubs de `System.cmd`
- `auth_test.exs` cobrindo sign/verify challenge

Sem isso, qualquer refactor quebra coisas silenciosamente.

---

**2. Corrigir bugs reais no código atual**

Analisando o código, encontrei problemas concretos:

Em `node.ex`, a função `validate_device` tem uma regex com erro de sintaxe:
```elixir
# BUGADO — vírgula dentro do character class, vai crashar
safe = device |> String.replace(~r/[^a-zA-Z0-9_\-\.\/], "", global: true)

# CORRETO
safe = device |> String.replace(~r/[^a-zA-Z0-9_\-\.\/]/, "")
```

Em `gateway.ex`, `send_text/2` retorna um novo state mas o caller em `handle_node_invoke` ignora esse retorno — o websocket state fica desatualizado após enviar a resposta do invoke.

Em `config/provider.ex`, o módulo declara `@impl true` mas não usa `use` de nenhum behaviour — vai dar warning em compile time e confundir quem for contribuir.

---

**3. Supervisão completa**

O `TaskSupervisor` é referenciado em `gateway.ex` mas nunca é adicionado à árvore de supervisão em `application.ex`. Se alguém chamar `node.invoke`, o processo vai crashar imediatamente com `noproc`.

```elixir
# application.ex — adicionar:
children = [
  {Registry, keys: :unique, name: ElixirClaw.Registry},
  {Task.Supervisor, name: ElixirClaw.TaskSupervisor}, # <- faltando
  {DynamicSupervisor, strategy: :one_for_one, name: ElixirClaw.Gateway.Supervisor}
]
```

---

## Fase 2 — Credibilidade técnica

**4. Config com Providers reais**

Hoje o código duplica lógica de config em três lugares: `application.ex`, `config/provider.ex`, e `cli.ex`. Isso causa bugs sutis onde a ordem de carregamento importa.

Solução: adotar `Config.Provider` do OTP corretamente, com um único ponto de entrada:

```elixir
# config/runtime.exs
import Config

config :elixir_claw,
  gateway_host: System.get_env("ELIXIR_CLAW_HOST", "127.0.0.1"),
  gateway_port: System.get_env("ELIXIR_CLAW_PORT", "18789") |> String.to_integer()
```

E remover a lógica duplicada dos outros módulos.

---

**5. Auth com criptografia real**

Hoje o `auth.ex` usa HMAC-SHA256 mas o `protocol.ex` tem esse comentário:

```elixir
defp sign_challenge(config, challenge, timestamp) do
  message = "#{challenge["nonce"]}#{timestamp}"
  # For now, return a placeholder. Real implementation would use Ed25519
  Base.encode16(:crypto.hash(:sha256, message))
end
```

Ou seja: a autenticação não funciona de verdade. A lib `ex_crypto` ou o pacote `ed25519` resolve com ~20 linhas.

---

**6. Logging estruturado**

Hoje o código usa `Logger.info("string")` em todo lugar. Para um agente que roda 24/7, você precisa saber *quando* cada evento aconteceu, *qual node*, *qual comando*.

```elixir
# Hoje
Logger.info("Connected successfully to Gateway")

# O que deveria ser
Logger.info("gateway_connected",
  node_id: state.config.node_id,
  host: state.gateway_host,
  attempt: state.reconnect_attempts
)
```

Isso habilita integração com Datadog, Loki, CloudWatch sem mudar o código depois.

---

## Fase 3 — Features que criam história

**7. Demo gravável em terminal**

Não é uma feature de código, é de produto. Um script que:
1. Sobe o node
2. Recebe um comando simulado
3. Executa e mostra o resultado

Usando `asciinema` para gravar e embutir no README. Isso sozinho pode dobrar os stars.

---

**8. Capabilities com feedback de progresso**

Hoje `screen.record` dispara um processo e retorna o path imediatamente. O gateway não sabe se a gravação terminou, falhou, ou está em andamento.

Implementar um sistema de streaming de eventos:

```elixir
# Emite eventos durante a execução
def execute("screen.record", args) do
  emit_event("recording.started", %{path: path})
  # ... grava ...
  emit_event("recording.finished", %{path: path, size: size})
end
```

---

**9. Phoenix LiveView Dashboard**

Está no roadmap do projeto mas é o item com maior impacto de visibilidade. Uma dashboard web mostrando:
- Status de conexão em tempo real
- Histórico de comandos executados
- Métricas de uptime

É o tipo de coisa que aparece em screenshot no Twitter e gera interesse orgânico.

---

**10. Integração direta com um LLM popular**

O maior gap de narrativa do projeto: ele é um "node client" mas para quê? Mostrar um exemplo completo onde Claude ou GPT-4 usa o ElixirClaw para fazer algo útil — tirar um screenshot quando você pede em linguagem natural — fecha o loop e cria uma história que as pessoas conseguem contar.

---

## Ordem de execução recomendada

```
Semana 1-2:  Fase 1 completa (bugs + TaskSupervisor + testes básicos)
Semana 3-4:  Auth real + Config unificado
Semana 5:    Logging estruturado + primeiro teste de stress (72h rodando)
Semana 6:    Demo gravado + README reescrito com o resultado do stress test
Semana 7-8:  Dashboard LiveView básico
Semana 9+:   Integração com LLM + post mostrando o resultado real
```

A Fase 1 é pré-requisito para tudo. Com os bugs atuais, qualquer pessoa que clonar e tentar usar o `node.invoke` vai ter uma má experiência — e uma má primeira impressão mata projetos open source antes de qualquer marketing.