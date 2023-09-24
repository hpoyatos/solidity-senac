em// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;

// Importação do contrato ERC20 do Senacoin e Ownable para uso do modificador onlyOwner
import "./Senacoin.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
Contrato: BolaoSenacoin
Autor: Henrique Poyatos
Data: 24 de setembro de 2023
Contrato de Bolão usando Senacoin (ERC20)
*/
contract BolaoSenacoin is Ownable {
    address private senacoinAddress;

    // A estrutura jogador guardará o nome do jogador e o número de apostas desta vez
    struct Jogador {
        string nome;
        address carteira;
        uint256 apostas;
        bool isValue;
    }

    // Uma estrutura de evento para guardar informações da Aposta
    event ApostaEvent(
        address indexed carteira,
        string nome,
        uint256 apostas,
        uint256 apostasTotal,
        uint256 premio
    );

    // Uma estrutura de "fim de jogo" para formalizar o ganhador e seu prêmio
    event FimDeJogoEvent(
        address indexed carteira,
        string ganhador,
        uint256 premio
    );

    // Atributos para armazenar as estruturas, jogadores, valores padrão de apostas, entre outros 
    mapping(address => Jogador) private jogadoresInfo;
    address private gerente;
    address[] private jogadores;
    address[] private apostas;
    uint256 public premio;
    uint256 public numApostas;
    uint256 public valorAposta;

    // apostar() guarda informações do jogador, lança a aposta e emite evento. A aposta tem valor padronizado.
    function apostar(string memory pNome) public {
        require(bytes(pNome).length > 0, "Nome deve ser fornecido");
        require(Senacoin(senacoinAddress).balanceOf(msg.sender) >= valorAposta, "Saldo insuficiente");
        if (jogadoresInfo[msg.sender].isValue == false) {
            jogadoresInfo[msg.sender] = Jogador({ nome: pNome, carteira: msg.sender, apostas: 1, isValue: true});
            jogadores.push(msg.sender);
        } else {
            jogadoresInfo[msg.sender].apostas = jogadoresInfo[msg.sender].apostas + 1;
        }
        Senacoin(senacoinAddress).burnFrom(msg.sender, valorAposta);
        apostas.push(msg.sender);
        numApostas++;
        premio = premio + valorAposta;
        emit ApostaEvent(msg.sender, jogadoresInfo[msg.sender].nome, jogadoresInfo[msg.sender].apostas, numApostas, premio);
    }

    // escolherGanhador() só pode ser acionada pelo gerente do contrato
    function escolherGanhador() public onlyOwner {
        require(apostas.length > 0, "Nenhum jogador participou do jogo");
        uint index = random() % apostas.length;
        Senacoin(senacoinAddress).mint(apostas[index], premio);
        if (jogadoresInfo[apostas[index]].isValue == true) {
            emit FimDeJogoEvent(apostas[index], jogadoresInfo[apostas[index]].nome, premio);
        }
        limpar();
    }

    function getJogadores() public view returns (address[] memory) {
        return jogadores;
    }

    function getApostas() public view returns (address[] memory) {
        return apostas;
    }

    function getJogadorPorAddress(address id) public view returns(string memory, address, uint256) {
        return (jogadoresInfo[id].nome, jogadoresInfo[id].carteira, jogadoresInfo[id].apostas);
    }

    function getGerente() public view returns (address) {
        return gerente;
    }

    function getPremio() public view returns (uint256) {
        return premio;
    }

    function getValorAposta() public view returns (uint256) {
        return valorAposta;
    }

    function setValorAposta(uint256 _valorAposta) public onlyOwner {
        require(_valorAposta > 0, "Valor da aposta deve ser maior que zero");
        valorAposta = _valorAposta;
    }

    // Limpar gera as estruturas para começar um novo jogo.
    function limpar() private {
        for (uint i=0;  i < jogadores.length;i++) {
            jogadoresInfo[jogadores[i]].isValue = false;
        }
        jogadores = new address[](0);
        apostas = new address[](0);
        numApostas = 0;
        premio = 0;
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, jogadores)));
    }

    // Construtor do contrato
    constructor(address _senacoinAddress) {
    gerente = msg.sender;
    numApostas = 0;
    premio = 0;
    senacoinAddress = _senacoinAddress;
    // Valor padrão 1SNC
    valorAposta = 1 * 10 ** Senacoin(senacoinAddress).decimals();
    }
}
