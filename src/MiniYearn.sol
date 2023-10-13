// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// contrato ERC20
import "solmate/tokens/ERC20.sol";
// IWrappedTokenGatewayV3 interface
import "aave-v3-periphery/interfaces/IWrappedTokenGatewayV3.sol";
// IERC20 interface
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
// para importar un contrato que es una consola (para poder hacer console.log como en Javascript)
import "hardhat/console.sol";

/*
    Información útil:
        0xD322A49006FC828F9B5B37Ab215F99B4E5caB19C -> direccion del contrato WETHGateway de AAVE
        0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2 -> Dirección de la Pool de AAVE
        0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8 -> Dirección del token ERC20 aEthWETH
*/
 

contract MiniYearn is ERC20 {

    error CantidadIncorrecta();
 
    // Creamos el token MY, que sigue el estandar ERC20 (MiniYearn hereda del contrato ERC20) y,
    // por lo tanto, es necesario poner su constructor
    constructor() ERC20("MiniYearns", "MY", 18) { 
                                                
    }
 
    function deposit() public payable {  
    // payable para poder transferir dinero (msg.value) a través de la función
        // no se puede enviar 0 Ether
        if(msg.value == 0) revert CantidadIncorrecta(); 
 
        IWrappedTokenGatewayV3(0xD322A49006FC828F9B5B37Ab215F99B4E5caB19C).depositETH{value: msg.value}(
            0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2, // Dirección de la Pool de AAVE
            address(this),                              // Dirección que va a recibir los tokens de Aave aWETH (Nuestro contrato)
            0                                           // Código de referido, 0 = no usamos
        );
 
        // _mint se hereda del contrato ERC20. Se crea nuestro token MY (que es un ERC20) y se envia al usuario
        _mint(msg.sender, msg.value);                                 
    }
 
    function withdraw(uint256 amount) public {
        // La amount corresponde a los tokens MY (expresado en unidades Wei) que deseamos retirar

        // No puedes retirar más cantidad de la que tienes
        if(amount > balanceOf[msg.sender]) revert CantidadIncorrecta(); 
        // el mapping balanceOf[address] se hereda del contrato ERC20 (esta puesto como public). Indica la cantidad
        // de MY que tiene esa dirección (en unidades Wei)
 
        // Calcular cuantos aTokens equivale el parametro `amount`(cantidad de MY que queremos retirar en Wei)
        // Los aTokens van aumentando de valor con el tiempo (AAVE da un porcentaje de interes)
        // Es necesario escalar la multiplicación ( /1e18 ) para quitar esos 0s de más
        uint256 amountToWithdraw = amount * getMiniYearnPrice() / 1e18;
        
        // IERC20 approve del token ERC20 aEthWETH (0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8) -> es necesario aprobar
        // que el contrato WETHGateway pueda mover nuestros aEthWETH que tiene el contrato MiniYearn
        IERC20(0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8).approve(0xD322A49006FC828F9B5B37Ab215F99B4E5caB19C, amountToWithdraw); 

        IWrappedTokenGatewayV3(0xD322A49006FC828F9B5B37Ab215F99B4E5caB19C).withdrawETH(
            0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2, // Dirección de la Pool
            amountToWithdraw,                           // Cantidad de tokens a retirar en unidades Wei 
            msg.sender                                  // Persona que va a recibir los ETH (ya están unwrapped)
        );
 
        // _burn se hereda del contrato ERC20. Quemamos los tokens MY que tiene el usuario
        _burn(msg.sender, amount); 
    }

    /*  
        cantidad de aEthWETH en el contrato MiniYearn / cantidad de tokens MiniYearn existentes (totalSupply) -> X aEthWETH/MY
        address(this) -> dirección del contrato MiniYearn
        IMPORTANTE -> en Solidity NO HAY DECIMALES -> es necesario escalar la división ( *1e18 ) para que desaparezca el punto decimal
        el resultado es en Wei (1e18 Wei = 1 Ether)
    */
    function getMiniYearnPrice() public view returns(uint256) {
      return IERC20(0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8).balanceOf(address(this)) *1e18 / totalSupply;
    }
 
    /* 
        devuelve la cantidad de aEthWETH en el contrato MiniYearn. Ésta va aumentando con el tiempo debido a la tasa
        de interés que ofrece el protocolo de AAVE --> getMiniYearnPrice() también va aumentando de valor. 
        El resultado es en Wei
    */
    function getATokenBalance() public view returns(uint256) {
      return IERC20(0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8).balanceOf(address(this));
    }
}
