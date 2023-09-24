// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;

import "./Senacoin.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SenacoinBolao is Ownable {
    address private senacoinAddress;

    struct Jogador {
        string nome;
        address carteira;
        uint256 apostas;
        bool isValue;
    }

    event ApostaEvent(
        address indexed carteira,
        string nome,
        uint256 apostas,
        uint256 apostasTotal,
        uint256 premio
    );

    event FimDeJogoEvent(
        address indexed carteira,
        string ganhador,
        uint256 premio
    );

    mapping(address => Jogador) private jogadoresInfo;
    address private gerente;
    address[] private jogadores;
    address[] private apostas;
    uint256 public premio;
    uint256 public numApostas;
    uint256 public valorAposta;

    function entrar(string memory pNome) public {
        if (Senacoin(senacoinAddress).balanceOf(msg.sender) >= valorAposta) {
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
    }

    function escolherGanhador() public onlyOwner {
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

    function getSaldo() public view returns (uint256) {
        return premio;
    }

    function getValorAposta() public view returns (uint256) {
        return valorAposta;
    }

    function setValorAposta(uint256 _valorAposta) public {
        valorAposta = _valorAposta;
    }

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

    constructor(address _senacoinAddress) {
    gerente = msg.sender;
    numApostas = 0;
    premio = 0;
    senacoinAddress = _senacoinAddress;
    valorAposta = 1 * 10 ** Senacoin(senacoinAddress).decimals();
    }
}
