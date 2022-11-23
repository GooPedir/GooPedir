import axios from "axios";
import  { useState, useContext, useEffect} from "react";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import './estilo/global.css';
import Global from "./estilo/global";
import { ButtonDemo } from "./componente/demo/ButtonDemo";
import { CardDemo } from "./componente/demo/card";
import { Button } from "primereact/button";
import { Carousel } from 'primereact/carousel';









var inicio = false;

function App() {
const BaseURL = "https://goopedir.com/";

  const [Empresa, setEmpresa] = useState('');
  const [CorPrincipal, setCorPrincipal] = useState('#000000');
  const [CorFonte, setCorFonte] = useState('#ffffff');
  const [Background, setBackground] = useState('');
  const [Logo, setLogo] = useState('');
  const [UserId, setUserId] = useState(1);
  const [DadosGeralEmpresa, setDadosGeralEmpresa] = useState([]);
  const [DadosCategoria, setDadosCategoria] = useState([]);

//Aki pode ser definido o cliente fixo
// const pathname = window.location.pathname.replace('/', '');
const pathname = 'Demo';
const link = "generica.php?tabela=ws_empresa&where=nome_empresa_link='"+pathname+"'";
// console.log(link);

const favicon = document.getElementById("icon");
const base = document.getElementById("baseurl");

// console.log(base?.getAttribute('href'));

const API = axios.create({
  baseURL: BaseURL+"/ws/v1/",
})  

if (inicio){

} else {
  inicio = true;
  API.get(link).then(
    function (response) {
      setDadosGeralEmpresa(response.data);
      console.log(DadosGeralEmpresa);
      // ValidaAbertura(response.data);
     
      setUserId(response.data[0][1])
      setEmpresa(response.data[0][2]);
      setCorPrincipal(response.data[0][74])
      setCorFonte(response.data[0][76])
      setBackground(BaseURL+'uploads/'+response.data[0]['img_header'])
      setLogo(BaseURL+'uploads/'+response.data[0]['img_logo'])
      document.title = response.data[0][2];
      favicon?.setAttribute('href', Logo);
        
  
      API.get('categoria.php?codigo='+UserId).then(
        function (response) {
                
          setDadosCategoria(response.data);
        }
      );
  
  
    }
  
  );  
  
}

const [products, setProducts] = useState([]);

const responsiveOptions = [
  {
      breakpoint: '1024px',
      numVisible: 3,
      numScroll: 3
  },
  {
      breakpoint: '600px',
      numVisible: 2,
      numScroll: 2
  },
  {
      breakpoint: '480px',
      numVisible: 1,
      numScroll: 1
  }
];



  return (
    <>  
  {/* <CardDemo id={1} mesa="MESA" numero="1" total="0,00" status="Livre"/> */}
    <Global/>
    
     <div className="container">
      <header>
      <p>Header</p>
      </header>
      <main>
        <p>Main</p>

      </main>
 
      
      <footer>
        <div className="container-sidebar">
          <div id="carrinho"> <Button icon="pi pi-shopping-cart" label="Carrinho" className="p-button-info" style={{ width: '100%', height:'100%'}} /></div>
          <div id="finalizar-pedido"> <Button icon="pi pi-shopping-cart" label="Finalizar Pedido" className="p-button-success" style={{ width: '100%', height:'100%'}} /></div>      
        </div>  
      </footer>
    </div>
  






   </>
  );
}


export default App;
