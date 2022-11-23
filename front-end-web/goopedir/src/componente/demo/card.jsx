
import React from 'react';
import { Card } from 'primereact/card';
import { Button } from 'primereact/button';

export const CardDemo = (props) => {

    console.log(props);
    return (
        <div>

            <Card title={props.mesa+' '+props.numero} style={{ width: '15rem', margin: '0.5em',  background: 'red' }}>
            <p className="m-0" style={{lineHeight: '1.5'}}>{'R$ '+props.total}</p>
            <p className="m-0" style={{lineHeight: '1.5'}}>{props.status}</p>
                
            </Card>
        </div>
    )
}
                 