// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.18 <0.9.0;

// Necessário importar o contrato do Senacoin (ERC20)
import "./Senacoin.sol";

/*
Contrato: GuardaSenacoin
Autor: Henrique Poyatos
Data: 24 de setembro de 2023
Contrato simples de custódia de Senacoin (ERC20)
*/
contract GuardaSenacoin {
    // Endereço do contrato de faz gestão de Senacoin
    address payable private senacoinAddress;
    
    // No momento do deploy, o endereço de contrato ativo de Senacoin deve ser fornecido
    constructor(address payable _tokenAddress) {
        senacoinAddress = _tokenAddress;
    }
    
    function depositar(uint _quantia) public payable {
        // Definindo 1SNC como quantidade mínima de depósito
        uint _qtdeMinima = 1*(10**Senacoin(senacoinAddress).decimals());
        // Validação da regra de quantidade mínima
        require(_quantia >= _qtdeMinima, "Envie pelo menos 1SNC");
        // Transfere a quantia da carteira do depositante para a carteira deste contrato
        Senacoin(senacoinAddress).transferFrom(msg.sender, address(this), _quantia);
    }
    
    // Exibe a quantidade de Senacoins (SNCs) custodiadas por este contrato.
    function getSaldo() public view returns (uint256) {
        return Senacoin(senacoinAddress).balanceOf(address(this));
    }

    function sacar(uint256 _quantia) public {
        // Valida se a quantia pedida no saque é inferior ou igual ao saldo total deste contrato.
        require(Senacoin(senacoinAddress).balanceOf(address(this)) >= _quantia, "O contrato nao tem fundos o suficiente");
        // Transfere Senacoins para quem chamou este contrato.
        Senacoin(senacoinAddress).transfer(msg.sender, _quantia);
    }
}
