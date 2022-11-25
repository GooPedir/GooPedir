import { InputText } from "primereact/inputtext";
import { useState } from "react";
import Cabecalho from "../../componentes/cabecalho/cabecalho";


function Produtos() {
    const [Busca, setBusca] = useState('');
    console.log(Busca);

    return (
        <>
        <Cabecalho/>

        <div className="field col-12 md:col-4">
        <span className="p-float-label mt-3 ">
            <InputText id="inputtext"  className="w-full" value={Busca} onChange={(e) => setBusca(e.target.value)}/>
            <label htmlFor="inputtext">Buscar Produtos  </label>
        </span>
        </div>

        {/* <div className="card">
            <div className="flex flex-column card-container green-container">
                <div className="flex align-items-center justify-content-center h-4rem bg-red-500 font-bold text-black border-round m-2">X Salada</div>                
            </div>
        </div> */}


<div className="relative card-container blue-container bg-red-500 border-500 hover:border-700 border-3 border-round border-white">
                            {/* <div className="static bg-blue-100 p-4 border-500 hover:border-700 border-3 border-round surface-overlay h-6rem w-6rem m-2 border-1 border-white-500">
                            <div className="flex flex-column card-container m-10">XXX</div>
                            </div> */}

                <div className="orderlist-demo">
                    <div className="product-item">
                        <div className="image-container">
                            <img src={`https://goopedir.com/uploads/images/2021/09/cliente-7-1632339093.jpg`}  alt={`test`} />
                        </div>
                        <div className="product-list-detail">
                            <h1 className="mb-2 font-bold text-white">Nome Produto</h1>                    
                            <span className="product-category bold text-white">Descrição</span>
                        </div>
                        <div className="product-list-action align-content-end ">
                            <h6 className="mb-2 bold text-white">R$ 0,00</h6>
                            <span className={`bold text-white product-badge status-${`item.inventoryStatus.toLowerCase()`}`}>10 em estoque</span>
                        </div>
                    </div>
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
  
  export default Produtos;
  