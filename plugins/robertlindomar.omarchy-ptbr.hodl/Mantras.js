// The chorus. Bitcoin culture talks to itself in slogans, and the whole point
// of this plugin is that the slogans show up unprompted — especially the one
// that says do nothing. No QML imports, so the CLI can read the same bank.

var HODL = [
  "HODL.",
  "HODL. Essa é a estratégia inteira.",
  "Você não é trader. HODL.",
  "Hold on for dear life.",
  "O plano sempre foi: não fazer nada.",
  "Afaste o zoom. Depois HODL.",
  "Vender é como se perder bitcoin.",
  "Quatro anos é o menor prazo útil.",
  "Tempo no mercado vence timing de mercado.",
  "Seu eu do futuro pede para você HODL.",
  "Ninguém se arrependeu de segurar por mais tempo.",
  "1 BTC = 1 BTC. HODL.",
  "Não faça nada. Faça bem.",
  "A mão mais forte na sala é a que não se move.",
  "Todo ciclo paga quem tem paciência.",
  "Você já tomou essa decisão. Pare de refazer."
]

var WISDOM = [
  "Sem suas chaves, sem suas moedas.",
  "Sem suas chaves, sem seu bitcoin.",
  "Don't trust. Verify.",
  "Bitcoin não é crypto.",
  "Bitcoin ≠ dinheiro. Bitcoin ≠ blockchain.",
  "21 milhões. Nunca mais, jamais.",
  "Seja seu próprio banco.",
  "Acumule sats. Mantenha a humildade.",
  "Cold storage não é opcional.",
  "Conserte o dinheiro, conserte o mundo.",
  "Tick tock, next block.",
  "Exchanges são onde o bitcoin some.",
  "Saque para autocustódia.",
  "Teste seu backup de seed phrase. Hoje.",
  "Uma carteira que você nunca restaurou não é backup.",
  "Volatilidade é o preço da entrada.",
  "Preço é o que você paga. Escassez é o que você ganha.",
  "Não existe segundo melhor.",
  "Bitcoin não liga para seus sentimentos.",
  "Deflação é uma feature.",
  "Rode seu próprio node.",
  "Verifique os 21M você mesmo. Esse é o ponto.",
  "Number go up é consequência, não plano.",
  "O halving já aconteceu. A matemática é paciente.",
  "Have fun staying poor — ou não, e acumule.",
  "Ninguém fica rico em um ciclo. Fica rico em quatro.",
  "Suas chaves, suas moedas. Chaves de outros, moedas de outros.",
  "Exchange é ponto de ônibus, não lar.",
  "Aprenda a pensar em sats. Essa é a unidade real.",
  "Um banco pode congelar sua conta. A matemática não.",
  "Inflação é um imposto que ninguém votou.",
  "O único ativo que você leva na cabeça ao cruzar uma fronteira.",
  "Ninguém precisa de permissão. Essa é a invenção inteira.",
  "A cada quatro anos, a mesma lição e o mesmo esquecimento.",
  "Ignore o ticker. Verifique o supply.",
  "O whitepaper tem nove páginas. Leia uma vez por ano.",
  "Se não consegue explicar para si mesmo, você tem demais.",
  "Custódia é habilidade, não compra.",
  "Multisig é mais barato que arrependimento.",
  "Escreva a seed em metal. Papel queima.",
  "Um backup não é backup.",
  "Bear market é para construir. Bull market é para se gabar.",
  "Alavancagem é como bitcoiners viram ex-bitcoiners.",
  "Você não vence o mercado. Você o sobrevive.",
  "Sem CEO para ligar, sem botão para apertar. Por design.",
  "A segunda melhor hora de comprar é uma ordem recorrente chata."
]

var MOON = [
  "TO THE MOON 🚀",
  "🚀 UP ONLY",
  "Esse não é o topo. Nunca é.",
  "FOMO detectado. Respire.",
  "Todo mundo é gênio num candle verde.",
  "Verde em todo lugar. Ainda não venda.",
  "Alguém está vendendo isso. Não seja alguém.",
  "Number go up technology, funcionando como projetado.",
  "Cuidado: isso parece o topo. Raramente é.",
  "Não cheque o preço mais 40 vezes hoje.",
  "Candles verdes são barulhentos. Convicção é silenciosa.",
  "Todo mundo é investidor de longo prazo até +40%.",
  "Parábolas acabam. Posse não precisa."
]

var UP = [
  "Verde quieto. Fique entediante.",
  "Para cima e para a direita. Continue acumulando.",
  "Subida estável. Nada a fazer aqui.",
  "Dia verde. Mesmo plano de um dia vermelho.",
  "Mantenha a humildade, acumule sats.",
  "Legal. Agora largue o celular.",
  "Não confunda uma boa semana com uma boa decisão."
]

var FLAT = [
  "Entediante é bullish.",
  "Lateralização é acumulação.",
  "Nada acontece, depois tudo acontece.",
  "Mercado caranguejo. Hora perfeita para não fazer nada.",
  "Preço flat, mesmos 21 milhões.",
  "Sem notícia é feature.",
  "Chop é onde o dinheiro impaciente sai."
]

var DOWN = [
  "Dia vermelho. Desconto detectado.",
  "Mãos fracas estão sendo entregues a você.",
  "Afaste o zoom. Essa barra desaparece.",
  "Dip é feature.",
  "FUD é temporário. Escassez não.",
  "Vermelho é a taxa da viagem.",
  "Sats baratos sempre parecem caros no momento."
]

var CRASH = [
  "FUD! FUD! FUD! Não venda em pânico.",
  "Sangue nas ruas. É aí que estão os sats.",
  "Bitcoin morreu 400+ vezes. Ainda aqui.",
  "This is fine. HODL.",
  "-30% é uma terça-feira. Afaste o zoom.",
  "Quem vende em pânico vai vender. Você faz DCA.",
  "O gráfico está vermelho. O teto de supply não.",
  "Nada quebrou. O preço está em promoção.",
  "Capitulação parece clareza. Não é.",
  "O gráfico está te testando, não o bitcoin."
]

var EXTREME_GREED = [
  "GANÂNCIA EXTREMA — se controle.",
  "Todo mundo está ganancioso. Cuidado.",
  "Euforia de pico não é entrada.",
  "Quando taxistas dão dicas, realize — ou não, e HODL.",
  "Euforia é a emoção mais cara."
]

var GREED = [
  "Ganância no ar. Mantenha o plano.",
  "FOMO é imposto sobre os impacientes."
]

var FEAR = [
  "Medo no mercado. Medo é onde sats são baratos.",
  "Outros estão com medo. Você conhece a frase."
]

var EXTREME_FEAR = [
  "MEDO EXTREMO — historicamente, um presente.",
  "Dor máxima, oportunidade máxima.",
  "Seja ganancioso quando outros têm medo.",
  "O fundo parece exatamente assim.",
  "As melhores entradas sempre parecem erro."
]

var PROFIT = [
  "Em lucro. Isso não é sinal de venda.",
  "P/L verde. Ganhos no papel ficam no papel até você estragar.",
  "Ganhando. Não faça nada, com maestria."
]

var LOSS = [
  "No vermelho é normal. Pergunte a quem comprou em 2021 em 2024.",
  "P/L vermelho é aluguel da viagem.",
  "No vermelho no papel. Só realiza se vender."
]

var REGIME_BANKS = {
  moon: MOON, up: UP, flat: FLAT, down: DOWN, crash: CRASH
}

// A stable index instead of Math.random: the same tick shows the same line
// on every repaint, and the phrase only turns over when the caller advances
// the seed.
function pick(bank, seed) {
  if (!bank || bank.length === 0) return ""
  var n = Math.abs(Math.floor(Number(seed) || 0))
  return bank[n % bank.length]
}

// The hero line under the price. Sentiment extremes outrank the daily move —
// "extreme greed" is the more useful warning on a +2% day — and every third
// rotation falls back to plain HODL, which is the message that matters.
function heroLine(regime, fngValue, seed) {
  var n = Math.abs(Math.floor(Number(seed) || 0))
  var fng = Number(fngValue)
  if (n % 3 === 2) return pick(HODL, n / 3)
  if (isFinite(fng)) {
    if (fng >= 80 && n % 3 === 1) return pick(EXTREME_GREED, n)
    if (fng <= 20 && n % 3 === 1) return pick(EXTREME_FEAR, n)
  }
  return pick(REGIME_BANKS[regime] || FLAT, n)
}

function sentimentLine(fngValue) {
  var fng = Number(fngValue)
  if (!isFinite(fng)) return ""
  if (fng <= 24) return pick(EXTREME_FEAR, fng)
  if (fng <= 44) return pick(FEAR, fng)
  if (fng <= 55) return pick(FLAT, fng)
  if (fng <= 74) return pick(GREED, fng)
  return pick(EXTREME_GREED, fng)
}

function positionLine(plPct, seed) {
  var n = Number(plPct)
  if (!isFinite(n)) return pick(HODL, seed)
  return n >= 0 ? pick(PROFIT, seed) : pick(LOSS, seed)
}

// Notification headline for a move that crossed the alert threshold. Loud on
// purpose — this is the one that interrupts.
function alertHeadline(regime, changePct) {
  if (regime === "moon") return "🚀 TO THE MOON"
  if (regime === "crash") return "🩸 FUD! Bitcoin despencando"
  return Number(changePct) >= 0 ? "Bitcoin subindo" : "Bitcoin caindo"
}

function alertBody(regime, seed) {
  if (regime === "moon") return pick(MOON, seed) + " Não entre em FOMO. " + pick(HODL, seed)
  if (regime === "crash") return pick(CRASH, seed) + " " + pick(HODL, seed + 1)
  return pick(REGIME_BANKS[regime] || FLAT, seed) + " " + pick(HODL, seed)
}

function reminder(seed) {
  var n = Math.abs(Math.floor(Number(seed) || 0))
  return n % 2 === 0 ? pick(HODL, n / 2) : pick(WISDOM, n)
}
