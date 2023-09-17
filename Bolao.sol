// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;

/*
Contrato Bolao
Criado por Henrique Poyatos para a demonstração de um contrato inteligente
*/
contract Bolao {
    // Atributo jogadores guarda múltiplos endereços das carteiras dos jogadores
    address payable[] private jogadores;
    // Atributo dono guarda a carteira do dono do bolão
    address private dono;

    // Estabelece o endereço da carteira do deploy como dono do contrato
    constructor() {
        dono = msg.sender;
    }

    // Função "pagável" a ser usada pelo apostador
    function apostar() public payable {
        //Assim que uma aposta for feita, guarde o endereço de carteira do apostador
        jogadores.push(payable(msg.sender));
    }

    // Função getJogadores() retorna os endereços de carteiras dos apostadores
    function getJogadores() public view returns (address payable[] memory) {
        return jogadores;
    }

    // Funcão retorna o valor total em custódia no momento
    function getSaldo() public view returns (uint) {
        return (payable(address(this))).balance;
    }

    // O modificador somenteDono, quando aplicado, restringe o uso da função 
    modifier somenteDono() {
        require(msg.sender == dono);
        _;
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, jogadores)));
    }

    // escolherVencedor sorteia um apostador e transfere todo o valor em custódia para ele
    function escolherVencedor() public somenteDono {
        uint index = random() % jogadores.length;
        jogadores[index].transfer(address(this).balance);
        jogadores = new address payable[](0);
    }
}
