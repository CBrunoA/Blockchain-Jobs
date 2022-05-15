//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

//SafeMath para operaciones seguras, (no ha sido usado).
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Loteria {

    using SafeMath for uint256;

    address payable owner;

    //Inicializamos el owner
    constructor(uint256 _numeroMaxTickets){
        owner = payable(msg.sender);
        numTicketsTotal = _numeroMaxTickets;
        numTicketsDisponibles = numTicketsTotal;
    }

    //Modifier para que solo pueda ejecutar el owner
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    //Solo lo puede ejecutar alquien que tenga un ticket
    modifier onlyTicket(){
        numTicketsUsuario[msg.sender] > 0;
        _;
    }

    //Variables
    //Las variables publicas son para checkear, y poder implementarlas en el front-end en caso de querer.
        //número premios
    uint256 id = 0;
        //Porcentaje de bote de cada premio
    mapping(uint256 => uint256) public porcentajePremio;   //id => porcentaje
        //Aciertos por premio
    mapping(uint256 => uint256) public aciertosPremios;    //id => aciertos
        //Jugador y tickets, tomaremos nota de cuantos tickets ha comprado el usuario para usar
    mapping(address => uint256) public numTicketsUsuario;  //usuario => tickets
        //Numero aciertos usuario
    mapping(address => uint256) public numAciertos;    //usuario => aciertos
        //Premios usuarios
    mapping(address => uint256) public premioUsuario;  //usuario => id premio (1,2,3..)
        //Premios cobrados
    mapping(uint256 => bool) public premioReclamado; //id => bool
        //Numero tickets totales
    uint256 numTicketsTotal;
        //Numero tickets disponibles
    uint256 numTicketsDisponibles;
        //Precio Ticket
    uint256 precioTicket;
        //Temporizador loteria
    uint256 tiempoLoteria = 1 weeks;
        //Numero random para la loteria
    uint256[] randomNums;

    //Events
    event TicketsComprado(uint256 _numeroTickets, uint256 _precioCompra, address _comprador);
    event TicketUsado(uint256[] _uso, address _ownerDelTicket);
    event PremioRepartido(uint256 _premioId, uint256 _cantidad, address _winner);

    /*FUNCIONES CONTROL*/

    //Función para establecer el precio del ticket, solo puede ejecutarla el owner
    function EstablecerPrecioTicket(uint256 _precio) public onlyOwner(){
        precioTicket = _precio;
    }


    //Función para establecer un nuevo premio
    function EstablecerNumPremiosYPorcentajes(uint256 _porcentaje, uint256 _aciertosPremio) public onlyOwner{
        require(_porcentaje <= 100, "No puede ser mayor al total");
        uint256 total = _porcentaje;
        for(uint256 i = 0; i < id; i++){
            total += porcentajePremio[i+1];
        }
        require(total <= 100, "El total no debe ser mayor a 100");

        id += 1;
        porcentajePremio[id] = _porcentaje;
        aciertosPremios[id] = _aciertosPremio;
    }

    /*Funcion modificar porcentaje
    ATENCION: Para modificar los porcentajes, para evitar problemas con el require, es recomendable ponerlos todos a 0, y posteriormente actualizarlos al valor deseado
    esto se debe a que si mientras modificamos, suman más que 100, dará error.
    */
    function ModificarPorcentajes(uint256 _id, uint256 _nuevoPorcentaje, uint256 _nuevoPremio) public onlyOwner{
        uint total = _nuevoPorcentaje;
        for(uint256 i = 1; i<id; i++){
            total += porcentajePremio[id];
        }
        require(total <= 100, "El total no puede ser mayor a 100");

        porcentajePremio[_id] = _nuevoPorcentaje;
        aciertosPremios[_id] = _nuevoPremio;
    }

    //Función generar números aleatorios, el rango establece el número máx.
    uint256 nonce = 0;
    function RandomNumbers(uint256 _rango, uint _i, string memory _palabra) internal returns (uint256) {
        nonce += uint256(keccak256(abi.encodePacked(msg.sender, nonce, _i, block.timestamp))) % (_rango+_i);
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce, _i, _palabra))) % _rango;
        return random;
    }

    //Funcion generar números del juego
    //PalabraALeatoria es una palabra random que poner al generar los numeros, desde "hola" hasta lo que quieras.
    function GenNumbers(uint256 _rango, uint256 _longitud, string memory _palabraAleatoria) public onlyOwner{
        uint[] memory _numeros = new uint[](_longitud);
        for(uint256 i = 0; i < _longitud; i++){
            //randomNums.push(RandomNumbers(_rango, i));
            _numeros[i] = RandomNumbers(_rango, i, _palabraAleatoria);
        }
        randomNums = _numeros;
    }

    //Funcion ver los numeros generados
    //Solo lo puede ver el dueño
    function VerNums() public view onlyOwner returns(uint256[] memory){
        return randomNums;
    }

    /*FUNCIONES USUARIO*/

    //Función comprar ticket
    function ComprarTicket(uint256 _numTickets) public payable {
        uint256 _costo = _numTickets*precioTicket;
        require(_numTickets <= numTicketsDisponibles && _numTickets > 0 && numTicketsDisponibles >= 0, "Error de compra. Motivos: no hay tantos, o no puedes comprar < 1, o no hay disponible esa cantidad");
        require(msg.value >= _costo, "No hay suficientes fondos");
        numTicketsDisponibles -= _numTickets;
        numTicketsUsuario[msg.sender] += _numTickets;
        emit TicketsComprado(_numTickets, _costo, msg.sender);
    }

    //Funcion elegir numeros
    function ElegirNumeros(uint[] memory _numeros) public onlyTicket{
        require(_numeros.length == randomNums.length, "Tienes que introducir el numero de numeros especificado");
        uint256 _numAciertos = 0;
        uint256 _premio = 0;
        for(uint256 i = 0; i < _numeros.length; i++){
            if(_numeros[i] == randomNums[i]){
                _numAciertos +=1;
            }
        }
        numAciertos[msg.sender] = _numAciertos;

        for(uint256 i = 1; i <= id; i++){
            if(aciertosPremios[i] == _numAciertos){
                _premio = i;
            }
        }
        premioUsuario[msg.sender] = _premio;


        /*for(uint256 i = 1; i < id; i++){
            if(aciertosPremios[i] == _numAciertos){
                _premio = i;
            }
        }*/
        if(premioReclamado[_premio] == false){
            RepartirPremios(_premio, msg.sender);
            premioReclamado[_premio] == true;
        }
        numTicketsUsuario[msg.sender] -= 1;
        emit TicketUsado(_numeros, msg.sender);
    }

    //Funcion repartir premios
    function RepartirPremios(uint256 _idPremio, address _to) internal{
        //Con el msg.sender ver porcentaje y enviarle el premio
        uint256 _monto = address(this).balance*porcentajePremio[_idPremio]/100;
        (bool success,) = payable(_to).call{value: address(this).balance*porcentajePremio[_idPremio]/100}("");
        require(success, "Payment Failed");
        emit PremioRepartido(_idPremio, _monto, msg.sender);
    }

    //Funcion retirar fondos
    //IMPORTANTE: Cuidado con retirar, si se retira todo los jugadores no recibiran el premio..
    function RetirarFondos(address _to, uint256 _cantidad) public onlyOwner returns(bool){
        require(_cantidad <= address(this).balance, "No hay suficientes fondos para retirar");
        (bool success,) = payable(_to).call{value: _cantidad}("");
        return success;
    }

    //Funcion ver tickets iniciales, precio...
    function VerParametrosIniciales() public view returns(uint256, uint256){
        return (numTicketsTotal, precioTicket);
    }

    //Función ver tickets Comprados
    function VerTicketsDisponibles() public view returns(uint256){
        return numTicketsDisponibles;
    }

    function VerFondos() public view onlyOwner returns(uint256){
        return address(this).balance;
    }

    function VerMisTickets() public view returns(uint256){
        uint256 _mistickets = numTicketsUsuario[msg.sender];
        return _mistickets;
    }
}
