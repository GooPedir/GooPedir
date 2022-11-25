import { InputText } from "primereact/inputtext";
import { useState } from "react";
import Cabecalho from "../../componentes/cabecalho/cabecalho";
import './categoria.css';

function Categorias() {
    const [Busca, setBusca] = useState('');
    console.log(Busca);

    return (
        <>
        <Cabecalho/>

        <div className="field col-12 md:col-4">
        <span className="p-float-label mt-3 ">
            <InputText id="inputtext"  className="w-full" value={Busca} onChange={(e) => setBusca(e.target.value)}/>
            <label htmlFor="inputtext">Buscar Categoria</label>
        </span>
        </div>

        <div className="card">
            <div className="flex flex-column card-container green-container">
                <div className="flex align-items-center justify-content-center h-4rem bg-red-500 font-bold text-black border-round m-2">X Salada</div>                
            </div>
        </div> 



{/* 
        <div className="card">
            <div className="flex flex-column card-container green-container">
                <div className="flex align-items-center bg-red-500 h-8rem font-bold text-black "> 
                



                </div>                
            </div>
        </div>         */}


        </>
    );
  }
  
  export default Categorias;
  