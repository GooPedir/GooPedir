import "primereact/resources/themes/lara-light-indigo/theme.css";  //theme
import "primereact/resources/primereact.min.css";                  //core css
import "primeicons/primeicons.css";                                //icons
import 'primeflex/primeflex.css';
 
import React from 'react';
import ReactDOM from 'react-dom/client';
import { Route,Routes, BrowserRouter } from "react-router-dom";


import App from './App';
import Login from './paginas/login/login';
import Home from "./paginas/home/home";
import Cabecalho from "./componentes/cabecalho/cabecalho";
import Mesa from "./paginas/mesa/mesa";
import Categorias from "./paginas/categorias/categorias";
import Produtos from "./paginas/produtos/produtos";


const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement
);
root.render(
  <React.StrictMode>
<BrowserRouter>
<Routes>
<Route element= { <Mesa />}  path="/" />
<Route element= { <Login />}  path="/login" />
<Route element= { <Categorias />}  path="/categoria" />
<Route element= { <Produtos />}  path="/produto" />
</Routes>
</BrowserRouter>

    {/* <Cabecalho/> */}
    {/* Falta colocar o react router */}
    {/* <Login /> Login ta feito, so falta validar */}
    {/* <Home /> */}
  </React.StrictMode>
);